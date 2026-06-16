#!/usr/bin/env bash
set -euo pipefail

app_name="${APP_NAME:-NotchMeter}"
binary_name="${BINARY_NAME:-notch-meter}"
bundle_id="${BUNDLE_ID:-dev.ttc9082.NotchMeter}"
version="${VERSION:-0.1.0}"
build_number="${BUILD_NUMBER:-1}"
configuration="${CONFIGURATION:-release}"
dist_dir="${DIST_DIR:-dist}"
volume_name="${VOLUME_NAME:-${app_name} Installer}"

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_dir="${root_dir}/${dist_dir}/${app_name}.app"
dmg_stage_dir="${root_dir}/${dist_dir}/dmg-stage"
contents_dir="${app_dir}/Contents"
macos_dir="${contents_dir}/MacOS"
resources_dir="${contents_dir}/Resources"
dmg_path="${root_dir}/${dist_dir}/${app_name}-${version}.dmg"
rw_dmg_path="${root_dir}/${dist_dir}/${app_name}-${version}-rw.dmg"
background_path="${dmg_stage_dir}/.background/background.png"
icon_source="${root_dir}/Sources/NotchMeter/Resources/AppIcon/AppIcon.png"
iconset_dir="${root_dir}/${dist_dir}/${app_name}.iconset"
icon_path="${resources_dir}/AppIcon.icns"

cd "${root_dir}"

rm -rf "${app_dir}" "${dmg_stage_dir}" "${dmg_path}" "${rw_dmg_path}" "${iconset_dir}"
mkdir -p "${macos_dir}" "${resources_dir}"

swift build -c "${configuration}" --product "${binary_name}"
cp ".build/${configuration}/${binary_name}" "${macos_dir}/${binary_name}"
chmod +x "${macos_dir}/${binary_name}"

if [[ -f "${icon_source}" ]]; then
  mkdir -p "${iconset_dir}"
  sips -z 16 16 "${icon_source}" --out "${iconset_dir}/icon_16x16.png" >/dev/null
  sips -z 32 32 "${icon_source}" --out "${iconset_dir}/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "${icon_source}" --out "${iconset_dir}/icon_32x32.png" >/dev/null
  sips -z 64 64 "${icon_source}" --out "${iconset_dir}/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "${icon_source}" --out "${iconset_dir}/icon_128x128.png" >/dev/null
  sips -z 256 256 "${icon_source}" --out "${iconset_dir}/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "${icon_source}" --out "${iconset_dir}/icon_256x256.png" >/dev/null
  sips -z 512 512 "${icon_source}" --out "${iconset_dir}/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "${icon_source}" --out "${iconset_dir}/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "${icon_source}" --out "${iconset_dir}/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "${iconset_dir}" -o "${icon_path}"
  rm -rf "${iconset_dir}"
fi

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
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
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

mkdir -p "${dmg_stage_dir}/.background"
cp -R "${app_dir}" "${dmg_stage_dir}/${app_name}.app"
ln -s /Applications "${dmg_stage_dir}/Applications"
swift "${root_dir}/scripts/create-dmg-background.swift" "${background_path}" "${app_name}"

hdiutil create \
  -volname "${volume_name}" \
  -srcfolder "${dmg_stage_dir}" \
  -ov \
  -fs HFS+ \
  -format UDRW \
  -size 96m \
  "${rw_dmg_path}"

mount_dir=""
device=""
detach_image() {
  for _ in {1..20}; do
    if [[ -n "${mount_dir}" ]]; then
      hdiutil detach "${mount_dir}" -quiet -force >/dev/null 2>&1 || true
    fi
    if [[ -n "${device}" ]]; then
      hdiutil detach "${device}" -quiet -force >/dev/null 2>&1 || true
    fi
    if ! hdiutil info | grep -Fq "${rw_dmg_path}"; then
      return 0
    fi
    sleep 0.5
  done
  echo "Could not detach temporary DMG: ${rw_dmg_path}" >&2
  hdiutil info >&2
  return 1
}
cleanup() {
  detach_image >/dev/null 2>&1 || true
  rm -rf "${rw_dmg_path}" "${dmg_stage_dir}"
}
trap cleanup EXIT

attach_output="$(hdiutil attach "${rw_dmg_path}" -readwrite -noverify -noautoopen)"
device="$(awk 'index($0, "/Volumes/") {print $1; exit}' <<<"${attach_output}")"
mount_dir="$(awk 'index($0, "/Volumes/") {print substr($0, index($0, "/Volumes/")); exit}' <<<"${attach_output}")"

if [[ -n "${device}" && -n "${mount_dir}" ]]; then
  if ! osascript <<OSA
tell application "Finder"
  set dmgFolder to POSIX file "${mount_dir}" as alias
  open dmgFolder
  delay 0.5
  set dmgWindow to container window of dmgFolder
  set current view of dmgWindow to icon view
  set toolbar visible of dmgWindow to false
  set statusbar visible of dmgWindow to false
  set the bounds of dmgWindow to {100, 100, 760, 520}
  set viewOptions to the icon view options of dmgWindow
  set arrangement of viewOptions to not arranged
  set icon size of viewOptions to 96
  set background picture of viewOptions to file ".background:background.png" of dmgFolder
  set position of item "${app_name}.app" of dmgFolder to {190, 250}
  set position of item "Applications" of dmgFolder to {470, 250}
  update dmgFolder without registering applications
  delay 1
  close dmgWindow
end tell
OSA
  then
    echo "Warning: Finder layout could not be applied; DMG will still contain the app, Applications link, and background asset." >&2
  fi
  sync
  for _ in {1..20}; do
    [[ -f "${mount_dir}/.DS_Store" ]] && break
    sleep 0.25
  done
  if [[ -f "${mount_dir}/.DS_Store" ]]; then
    cp "${mount_dir}/.DS_Store" "${dmg_stage_dir}/.DS_Store"
  else
    echo "Warning: Finder did not create .DS_Store; icon positions/background may use Finder defaults." >&2
  fi
  rm -rf "${mount_dir}/.fseventsd" "${mount_dir}/.Trashes"
  osascript -e 'tell application "Finder" to eject disk "'"${volume_name}"'"' >/dev/null 2>&1 || true
  detach_image
  device=""
  mount_dir=""
fi

hdiutil convert "${rw_dmg_path}" -format UDZO -imagekey zlib-level=9 -ov -o "${dmg_path}" >/dev/null

echo "${dmg_path}"
