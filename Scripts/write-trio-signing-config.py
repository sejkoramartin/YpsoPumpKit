"""Generate a local config for a future signed simulation build; no Apple API access."""
import os
import re
import sys
from pathlib import Path
team = os.environ.get('APPLE_TEAM_ID', '')
if not re.fullmatch('[A-Z0-9]{10}', team):
    raise SystemExit('Set APPLE_TEAM_ID to your ten-character Apple Developer team ID')
target = Path(sys.argv[1])
if target.exists():
    raise SystemExit('Refusing to overwrite an existing config')
bundle = f'org.ypsopumpkit.{team}.trio.sim'
target.write_text(f'''// Offline simulation only. Not registered or signed by this script.
APP_DISPLAY_NAME = Ypso Trio SIM
APP_URL_SCHEME = ypso-trio-sim
DEVELOPER_TEAM = {team}
BUNDLE_IDENTIFIER = {bundle}
TRIO_APP_GROUP_ID = group.{bundle}
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) YPSO_SIMULATION_ONLY
''')
print(f'Wrote local simulation config to {target}')
