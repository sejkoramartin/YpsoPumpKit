"""Install explicitly supplied App Store profiles on an ephemeral macOS runner."""
import base64
import datetime
import os
import plistlib
import re
import subprocess
from pathlib import Path


def validate(profile, team, bundle):
    ent = profile['Entitlements']
    if profile['TeamIdentifier'] != [team]:
        raise ValueError('Profile belongs to a different team')
    if ent.get('application-identifier') != f'{team}.{bundle}':
        raise ValueError('Profile does not match the simulator bundle')
    if ent.get('get-task-allow') or profile.get('ProvisionedDevices') or profile.get('ProvisionsAllDevices'):
        raise ValueError('An App Store distribution profile is required')
    if profile['ExpirationDate'].replace(tzinfo=datetime.timezone.utc) <= datetime.datetime.now(datetime.timezone.utc):
        raise ValueError('Profile has expired')
    if not re.fullmatch(r'[A-Fa-f0-9-]{36}', profile['UUID']):
        raise ValueError('Invalid profile UUID')


def main():
    team = os.environ['APPLE_TEAM_ID']
    if not re.fullmatch(r'[A-Z0-9]{10}', team):
        raise ValueError('Invalid Apple team ID')
    bundle = f'org.ypsopumpkit.{team}.trio.sim'
    root = Path(os.environ['RUNNER_TEMP']) / 'ypso-signing'
    root.mkdir(mode=0o700, exist_ok=True)
    mapping = {}
    for suffix, secret in [('', 'PROFILE_APP'), ('.watchkitapp', 'PROFILE_WATCH'),
                           ('.watchkitapp.TrioWatchComplication', 'PROFILE_COMPLICATION'),
                           ('.LiveActivity', 'PROFILE_ACTIVITY')]:
        content = base64.b64decode(os.environ[secret], validate=True)
        path = root / f'{secret}.mobileprovision'
        path.write_bytes(content)
        path.chmod(0o600)
        decoded = subprocess.run(['security', 'cms', '-D', '-i', str(path)], check=True, capture_output=True).stdout
        profile = plistlib.loads(decoded)
        validate(profile, team, bundle + suffix)
        # Xcode 16+ location; also install in legacy location for tooling compatibility.
        for location in ['Library/Developer/Xcode/UserData/Provisioning Profiles',
                         'Library/MobileDevice/Provisioning Profiles']:
            dest = Path.home() / location
            dest.mkdir(parents=True, exist_ok=True)
            installed = dest / (profile['UUID'] + '.mobileprovision')
            installed.write_bytes(content)
            installed.chmod(0o600)
        mapping[bundle + suffix] = profile['UUID']
    import json
    (root / 'profiles.json').write_text(json.dumps(mapping))
    (root / 'certificate.p12').write_bytes(base64.b64decode(os.environ['DISTRIBUTION_P12'], validate=True))
    (root / 'certificate.p12').chmod(0o600)
    print('Validated four simulator App Store profiles')


if __name__ == '__main__':
    main()
