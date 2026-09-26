#!/usr/bin/env bash
set -euo pipefail

# Find adb
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
    echo "Please ensure Android SDK platform-tools are installed, or set ANDROID_HOME."
    exit 1
fi

echo "🔍 Using ADB: $ADB_BIN"
echo "📱 Checking connected devices..."
DEVICES="$("$ADB_BIN" devices | grep -v "List of devices" | grep "device$" || true)"

if [[ -z "$DEVICES" ]]; then
    echo "⚠️  No authorized Android devices detected via USB."
    echo "   Ensure USB Debugging is enabled on your phone and you accepted the RSA prompt."
    exit 1
fi

echo "✅ Device found:"
echo "$DEVICES"

PORT="${1:-8765}"
echo "🔌 Setting up ADB reverse tunnel on port $PORT..."
"$ADB_BIN" reverse "tcp:$PORT" "tcp:$PORT"

echo ""
echo "🎉 USB Tunnel Established Successfully!"
echo "   Android Phone (localhost:$PORT) ────[USB]────> NotchDeck Host (:8765)"
echo "   In the Android NotchDeck app, select 'USB Mode' to connect to ws://127.0.0.1:$PORT"
