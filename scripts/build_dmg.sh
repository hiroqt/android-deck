#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_BUNDLE="$BUILD_DIR/NotchDeck.app"
DMG_STAGE="$BUILD_DIR/dmg_stage"
OUTPUT_DMG="$BUILD_DIR/NotchDeck.dmg"
WEB_DOWNLOADS_DIR="$ROOT_DIR/web/public/downloads"
WEB_PUBLIC_DIR="$ROOT_DIR/web/public"

echo "=========================================================="
echo "🚀 Building NotchDeck Standalone macOS App & DMG Release"
echo "=========================================================="

# 1. Compile macOS Native App in Release mode
echo "==> 1/6 Building NotchDeck Swift release binary..."
cd "$ROOT_DIR/macos/NotchDeck"
swift build -c release

RELEASE_BIN="$ROOT_DIR/macos/NotchDeck/.build/release/NotchDeck"
if [[ ! -f "$RELEASE_BIN" ]]; then
    echo "❌ Error: Release binary not found at $RELEASE_BIN"
    exit 1
fi

# 2. Ensure Android APK is available
echo "==> 2/6 Verifying Android APK build..."
APK_SRC="$ROOT_DIR/android/app/build/outputs/apk/debug/app-debug.apk"
if [[ ! -f "$APK_SRC" ]]; then
    echo "    Compiling Android APK (assembleDebug)..."
    cd "$ROOT_DIR/android"
    ./gradlew assembleDebug
fi

if [[ ! -f "$APK_SRC" ]]; then
    echo "❌ Error: Android APK not found at $APK_SRC"
    exit 1
fi
echo "    Found APK ($(du -h "$APK_SRC" | cut -f1))"

# 3. Create .app bundle structure
echo "==> 3/6 Assembling NotchDeck.app bundle..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources/portal"

# Copy binary
cp "$RELEASE_BIN" "$APP_BUNDLE/Contents/MacOS/NotchDeck"
chmod +x "$APP_BUNDLE/Contents/MacOS/NotchDeck"

# Generate & copy AppIcon
ICONSET_TMP="/tmp/NotchDeckIcon.iconset"
rm -rf "$ICONSET_TMP"
swift "$SCRIPT_DIR/generate_icon.swift" "$ICONSET_TMP"
iconutil -c icns "$ICONSET_TMP" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET_TMP"

# Copy embedded APK portal & assets
cp "$SCRIPT_DIR/serve_portal.py" "$APP_BUNDLE/Contents/Resources/serve_portal.py"
chmod +x "$APP_BUNDLE/Contents/Resources/serve_portal.py"
cp "$SCRIPT_DIR/portal/index.html" "$APP_BUNDLE/Contents/Resources/portal/index.html"
cp "$APK_SRC" "$APP_BUNDLE/Contents/Resources/NotchDeck.apk"

# Generate Info.plist
cat << 'EOF' > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>NotchDeck</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.arnel.NotchDeck</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>NotchDeck</string>
    <key>CFBundleDisplayName</key>
    <string>NotchDeck</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>NotchDeck requires Apple Events permission to launch and control your configured shortcuts.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>NotchDeck uses Accessibility to dock its liquid glass HUD directly to your MacBook camera notch.</string>
</dict>
</plist>
EOF

# 4. Codesign bundle ad-hoc to clear Gatekeeper quarantine friction
echo "==> 4/6 Ad-hoc code signing NotchDeck.app..."
xattr -cr "$APP_BUNDLE" || true
codesign --force --deep --sign - "$APP_BUNDLE"

# 5. Package into DMG with Applications symlink
echo "==> 5/6 Packaging NotchDeck.dmg with Applications drop-target..."
mkdir -p "$DMG_STAGE"
cp -R "$APP_BUNDLE" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"

rm -f "$OUTPUT_DMG"
hdiutil create -volname "NotchDeck" \
               -srcfolder "$DMG_STAGE" \
               -ov \
               -format UDZO \
               "$OUTPUT_DMG"

# Clean up stage folder
rm -rf "$DMG_STAGE"

# 6. Publish DMG to Web Public Assets
echo "==> 6/6 Publishing latest release DMG to Web..."
mkdir -p "$WEB_DOWNLOADS_DIR"
cp "$OUTPUT_DMG" "$WEB_DOWNLOADS_DIR/NotchDeck.dmg"
cp "$OUTPUT_DMG" "$WEB_PUBLIC_DIR/NotchDeck.dmg"

echo "=========================================================="
echo "🎉 Build & Release Complete!"
echo "   macOS App:  $APP_BUNDLE"
echo "   macOS DMG:  $OUTPUT_DMG ($(du -h "$OUTPUT_DMG" | cut -f1))"
echo "   Web Asset:  $WEB_DOWNLOADS_DIR/NotchDeck.dmg"
echo "=========================================================="
