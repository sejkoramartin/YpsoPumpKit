#!/usr/bin/env bash
set -euo pipefail
package_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="${1:?Usage: prepare-trio-ci.sh NEW_BUILD_DIRECTORY}"
[[ ! -e "$build_root" ]] || { echo 'Refusing to overwrite an existing build directory' >&2; exit 1; }
mkdir -p "$build_root"
git clone --no-checkout https://github.com/nightscout/Trio.git "$build_root/Trio"
git -C "$build_root/Trio" checkout 0b29cd53415e7f0e668677749cad8daf81c68c2f
git -C "$build_root/Trio" submodule update --init --recursive --depth 1 --jobs 4
ln -s "$package_root" "$build_root/YpsoPumpKit"
git -C "$build_root/Trio" apply --check "$package_root/Integration/Trio/simulator.patch"
git -C "$build_root/Trio" apply "$package_root/Integration/Trio/simulator.patch"
cat > "$build_root/Trio/ConfigOverride.xcconfig" <<'CONFIG'
APP_DISPLAY_NAME = Ypso Trio SIM
APP_URL_SCHEME = ypso-trio-sim
DEVELOPER_TEAM =
BUNDLE_IDENTIFIER = org.ypsopumpkit.trio.simulator
TRIO_APP_GROUP_ID = group.org.ypsopumpkit.trio.simulator
CONFIG
python3 "$package_root/Scripts/check-trio-isolation.py" "$build_root/Trio"
