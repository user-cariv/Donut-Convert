#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/Donut.app"
ICONSET_PATH="$BUILD_DIR/Donut.iconset"
DMG_PATH="$BUILD_DIR/Install Donut.dmg"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$ICONSET_PATH"

SOURCE_LOGO="$PROJECT_DIR/DonutLogo.jpg"

if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "Xcode is required to package Donut." >&2
    exit 1
fi

if ! command -v sips >/dev/null 2>&1 || ! command -v iconutil >/dev/null 2>&1; then
    echo "macOS image tools sips and iconutil are required." >&2
    exit 1
fi

for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$SOURCE_LOGO" \
        --out "$ICONSET_PATH/icon_${size}x${size}.png" >/dev/null
    double_size=$((size * 2))
    sips -z "$double_size" "$double_size" "$SOURCE_LOGO" \
        --out "$ICONSET_PATH/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil --convert icns "$ICONSET_PATH" --output "$BUILD_DIR/Donut.icns"
cp "$BUILD_DIR/Donut.icns" "$PROJECT_DIR/Donut.icns"

xcodebuild \
    -project "$PROJECT_DIR/Donut.xcodeproj" \
    -scheme Donut \
    -configuration Release \
    CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

cp "$BUILD_DIR/Donut.icns" "$APP_PATH/Contents/Resources/Donut.icns"
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile Donut.icns" \
    "$APP_PATH/Contents/Info.plist"
touch "$APP_PATH"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "Install Donut" \
    -srcfolder "$APP_PATH" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

echo "Created: $DMG_PATH"
