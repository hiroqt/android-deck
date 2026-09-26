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
echo "🔌 Setting up ADB reverse tunnel on port $PORT (WebSocket Server)..."
"$ADB_BIN" reverse "tcp:$PORT" "tcp:$PORT"

PORTAL_PORT="8080"
echo "📦 Setting up ADB reverse tunnel on port $PORTAL_PORT (APK Download Portal)..."
"$ADB_BIN" reverse "tcp:$PORTAL_PORT" "tcp:$PORTAL_PORT" || true

echo ""
echo "🎉 USB Tunnel Established Successfully!"
echo "   📱 Download APK over USB:   http://127.0.0.1:$PORTAL_PORT/NotchDeck.apk"
echo "   ⚡ NotchDeck Host Socket:   ws://127.0.0.1:$PORT"
echo "   In the Android NotchDeck app, select 'USB Mode' to connect to ws://127.0.0.1:$PORT"
