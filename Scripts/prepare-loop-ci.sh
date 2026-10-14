#!/usr/bin/env bash
# Downloads only public source. Never signs, installs or runs against hardware.
set -euo pipefail
package_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="${1:?Usage: prepare-loop-ci.sh NEW_BUILD_DIRECTORY}"
if [[ -e "$build_root" ]]; then
  echo "Refusing to overwrite existing directory: $build_root" >&2
  exit 1
fi
mkdir -p "$build_root"
git clone --no-checkout https://github.com/LoopKit/LoopWorkspace.git "$build_root/LoopWorkspace"
git -C "$build_root/LoopWorkspace" checkout 548b33245198eaae165c094c9c68fe333cb69c05
git -C "$build_root/LoopWorkspace" submodule update --init --recursive --depth 1 --jobs 4
workspace="$build_root/LoopWorkspace"
expected_loop=c30b5c89b1dc4151628f33f1384dd4796eaeeec2
[[ "$(git -C "$workspace/Loop" rev-parse HEAD)" == "$expected_loop" ]]
ln -s "$package_root" "$workspace/YpsoPumpKit"
git -C "$workspace/Loop" apply --check "$package_root/Integration/Loop/simulator.patch"
git -C "$workspace/Loop" apply "$package_root/Integration/Loop/simulator.patch"
# Raise only Loop's deployment target; dependencies retain their own higher minima.
python3 - "$workspace/Loop/Loop.xcodeproj/project.pbxproj" <<'PYTARGET'
from pathlib import Path
import sys
project = Path(sys.argv[1])
source = project.read_text()
assert 'IPHONEOS_DEPLOYMENT_TARGET = 15.1;' in source
project.write_text(source.replace('IPHONEOS_DEPLOYMENT_TARGET = 15.1;',
                                  'IPHONEOS_DEPLOYMENT_TARGET = 16.0;'))
PYTARGET
cat >> "$workspace/LoopConfigOverride.xcconfig" <<'CONFIG'

// Simulator-only research build. Device compilation is blocked in the source patch.
MAIN_APP_BUNDLE_IDENTIFIER = com.local.ypsopump.simulator
MAIN_APP_DISPLAY_NAME = Ypso Simulator
URL_SCHEME_NAME = ypso-simulator
CONFIG
python3 - "$workspace/Loop/Loop/Managers/DeviceDataManager.swift" <<'PY'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
assert '#if !targetEnvironment(simulator)\n#error(' in s
assert 'guard identifier == MockPumpManager.pluginIdentifier else { return nil }' in s
assert 'state.bolusEnactmentShouldError = true' in s
assert 'state.tempBasalEnactmentShouldError = true' in s
print('Verified simulator-only Loop guards')
PY
