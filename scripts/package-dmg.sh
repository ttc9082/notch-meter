#!/usr/bin/env bash
set -euo pipefail

app_name="${APP_NAME:-NotchMeter}"
binary_name="${BINARY_NAME:-notch-meter}"
bundle_id="${BUNDLE_ID:-dev.ttc9082.NotchMeter}"
version="${VERSION:-0.1.0}"
build_number="${BUILD_NUMBER:-1}"
configuration="${CONFIGURATION:-release}"
dist_dir="${DIST_DIR:-dist}"

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_dir="${root_dir}/${dist_dir}/${app_name}.app"
contents_dir="${app_dir}/Contents"
macos_dir="${contents_dir}/MacOS"
resources_dir="${contents_dir}/Resources"
dmg_path="${root_dir}/${dist_dir}/${app_name}-${version}.dmg"

cd "${root_dir}"

rm -rf "${app_dir}" "${dmg_path}"
mkdir -p "${macos_dir}" "${resources_dir}"

swift build -c "${configuration}" --product "${binary_name}"
cp ".build/${configuration}/${binary_name}" "${macos_dir}/${binary_name}"
chmod +x "${macos_dir}/${binary_name}"

cat > "${contents_dir}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${binary_name}</string>
    <key>CFBundleIdentifier</key>
    <string>${bundle_id}</string>
    <key>CFBundleName</key>
    <string>${app_name}</string>
    <key>CFBundleDisplayName</key>
    <string>${app_name}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${version}</string>
    <key>CFBundleVersion</key>
    <string>${build_number}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "${app_dir}"
fi

hdiutil create \
  -volname "${app_name}" \
  -srcfolder "${app_dir}" \
  -ov \
  -format UDZO \
  "${dmg_path}"

echo "${dmg_path}"
