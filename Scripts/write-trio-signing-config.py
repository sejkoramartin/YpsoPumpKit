"""Prepare local identity settings; never register, sign, upload or contact Apple."""
import argparse
import os
import re
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('destination', type=Path)
parser.add_argument('--checkout', action='store_true', help='Apply to a freshly prepared simulation checkout')
args = parser.parse_args()
team = os.environ.get('APPLE_TEAM_ID', '')
if not re.fullmatch('[A-Z0-9]{10}', team):
    raise SystemExit('Set APPLE_TEAM_ID to your ten-character Apple Developer team ID')
bundle = f'org.ypsopumpkit.{team}.trio.sim'
values = {
    'APP_DISPLAY_NAME': 'Ypso Trio SIM',
    'APP_URL_SCHEME': 'ypso-trio-sim',
    'DEVELOPER_TEAM': team,
    'BUNDLE_IDENTIFIER': bundle,
    'TRIO_APP_GROUP_ID': f'group.{bundle}',
}
text = '// Offline simulation only. Not registered or signed by this script.\n'
text += ''.join(f'{key} = {value}\n' for key, value in values.items())
text += 'SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) YPSO_SIMULATION_ONLY\n'
if not args.checkout:
    if args.destination.exists():
        raise SystemExit('Refusing to overwrite an existing config')
    args.destination.write_text(text)
else:
    # Fastlane reads Config.xcconfig directly; Xcode reads its overrides too.
    # Update both consistently, only from the known fresh simulation setup.
    main = args.destination / 'Config.xcconfig'
    override = args.destination / 'ConfigOverride.xcconfig'
    source, current_override = main.read_text(), override.read_text()
    if 'YPSO_SIMULATION_ONLY' not in source:
        raise SystemExit('Not a prepared simulation checkout')
    if 'BUNDLE_IDENTIFIER = org.nightscout.$(DEVELOPMENT_TEAM).trio' not in source:
        raise SystemExit('Refusing to replace a previously configured app identity')
    if 'BUNDLE_IDENTIFIER = org.ypsopumpkit.trio.simulator\n' not in current_override:
        raise SystemExit('Refusing to replace an unknown override')
    for key, value in values.items():
        source, count = re.subn(r'^' + re.escape(key) + r'\s*=.*$', f'{key} = {value}', source, flags=re.M)
        if count != 1:
            raise SystemExit(f'Expected exactly one setting for {key}')
    main.write_text(source)
    override.write_text(text)
print(f'Prepared local identity at {args.destination}; no Apple resources created')
