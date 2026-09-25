#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ADB_BIN=""
if command -v adb &> /dev/null; then
    ADB_BIN="$(command -v adb)"
elif [[ -x "${ANDROID_HOME:-}/platform-tools/adb" ]]; then
    ADB_BIN="${ANDROID_HOME}/platform-tools/adb"
elif [[ -x "${HOME}/Library/Android/sdk/platform-tools/adb" ]]; then
    ADB_BIN="${HOME}/Library/Android/sdk/platform-tools/adb"
fi

if [[ -z "$ADB_BIN" ]]; then
    echo "❌ Error: 'adb' executable not found."
    exit 1
fi

APK="$ROOT_DIR/android/app/build/outputs/apk/debug/app-debug.apk"
if [[ ! -f "$APK" ]]; then
    echo "Building APK first..."
    "$ROOT_DIR/android/gradlew" -p "$ROOT_DIR/android" assembleDebug
fi

echo "📱 Installing MacDeck on connected device..."
"$ADB_BIN" install -r "$APK"

echo "🚀 Launching MacDeck on Android..."
"$ADB_BIN" shell am start -n com.macdeck.client/.MainActivity

echo "✅ Ready!"
