#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=${1:-v1.0.0-rc1}
DMG_NAME="DJOneHub-macOS-universal-${VERSION}.dmg"
STAGE="${ROOT_DIR}/dist/dmg-stage-universal"
DMG="${ROOT_DIR}/dist/${DMG_NAME}"
CHECKSUM="${DMG}.sha256"
NOTIFIER_SRC="${ROOT_DIR}/macos/DJOneHubNotifier"
BUILD_ROOT="${TMPDIR:-/tmp}/djonehub-macos-package-universal"

echo "==> 1/4 构建通用主程序（arm64 + x86_64）"
"${ROOT_DIR}/scripts/package-macos-universal.sh" "${VERSION}"

echo "==> 2/4 构建通用通知助手"
mkdir -p "${BUILD_ROOT}/local-cache/clang" "${BUILD_ROOT}/local-cache/swiftpm"
export CLANG_MODULE_CACHE_PATH="${BUILD_ROOT}/local-cache/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="${BUILD_ROOT}/local-cache/clang"
export SWIFTPM_CUSTOM_CACHE_PATH="${BUILD_ROOT}/local-cache/swiftpm"
cd "${NOTIFIER_SRC}"
swift build --disable-sandbox -c release
"${NOTIFIER_SRC}/.build/release/DJOneHubNotifier" --self-test
xcrun swiftc -O -target x86_64-apple-macosx13.0 Sources/DJOneHubNotifier/*.swift -o "${BUILD_ROOT}/notifier-x86_64"
lipo -create "${NOTIFIER_SRC}/.build/release/DJOneHubNotifier" "${BUILD_ROOT}/notifier-x86_64" \
  -output "${BUILD_ROOT}/DJOneHubNotifier-universal"
file "${BUILD_ROOT}/DJOneHubNotifier-universal" | cut -c1-120
for arch in arm64 x86_64; do
  lipo "${BUILD_ROOT}/DJOneHubNotifier-universal" -verify_arch "${arch}"
done

echo "==> 3/4 组装安装目录"
rm -rf "${STAGE}"
mkdir -p "${STAGE}/DJOneHubNotifier.app/Contents/MacOS" "${STAGE}/DJOneHubNotifier.app/Contents/Resources"
ditto --norsrc --noextattr --noqtn --noacl "${ROOT_DIR}/dist/release/DJOneHub-macOS-universal-${VERSION}" "${STAGE}/djonehub"
cp "${BUILD_ROOT}/DJOneHubNotifier-universal" "${STAGE}/DJOneHubNotifier.app/Contents/MacOS/DJOneHubNotifier"
cp "${NOTIFIER_SRC}/Info.plist" "${STAGE}/DJOneHubNotifier.app/Contents/Info.plist"
cp "${NOTIFIER_SRC}/Resources/AppIcon.icns" "${STAGE}/DJOneHubNotifier.app/Contents/Resources/AppIcon.icns"
chmod 755 "${STAGE}/DJOneHubNotifier.app/Contents/MacOS/DJOneHubNotifier"
codesign --force --deep --sign - "${STAGE}/DJOneHubNotifier.app"
codesign --verify --deep --strict "${STAGE}/DJOneHubNotifier.app"
plutil -lint "${STAGE}/DJOneHubNotifier.app/Contents/Info.plist"
for binary in \
  "${STAGE}/DJOneHubNotifier.app/Contents/MacOS/DJOneHubNotifier" \
  "${STAGE}/djonehub/bin/djonehub-macos" \
  "${STAGE}/djonehub/lib/libusb-1.0.0.dylib"
do
  for arch in arm64 x86_64; do
    lipo "${binary}" -verify_arch "${arch}"
  done
done
cp "${ROOT_DIR}/scripts/dmg/安装 DJOneHub.command" "${STAGE}/安装 DJOneHub.command"
cp "${ROOT_DIR}/scripts/dmg/卸载 DJOneHub.command" "${STAGE}/卸载 DJOneHub.command"
cp "${ROOT_DIR}/scripts/dmg/使用说明.txt" "${STAGE}/使用说明.txt"
chmod 755 "${STAGE}/安装 DJOneHub.command" "${STAGE}/卸载 DJOneHub.command"

echo "==> 4/4 生成 DMG"
rm -f "${DMG}" "${CHECKSUM}"
hdiutil create -volname "DJOneHub" -srcfolder "${STAGE}" -ov -format UDZO "${DMG}"
hdiutil verify "${DMG}"
(
  cd "$(dirname -- "${DMG}")"
  shasum -a 256 "$(basename -- "${DMG}")" >"$(basename -- "${CHECKSUM}")"
)

echo
echo "完成：${DMG}"
echo "校验：${CHECKSUM}"
