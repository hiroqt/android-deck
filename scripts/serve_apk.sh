#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APK_DIR="$ROOT_DIR/android/app/build/outputs/apk/debug"
APK="$APK_DIR/app-debug.apk"

if [[ ! -f "$APK" ]]; then
    echo "Building APK first..."
    "$ROOT_DIR/android/gradlew" -p "$ROOT_DIR/android" assembleDebug
fi

IP="$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)"
PORT="8080"

echo "=================================================="
echo "  📲 Wireless APK Installer Server"
echo "=================================================="
echo "On your Android phone, open Chrome or any browser and visit:"
echo ""
echo "   👉 http://$IP:$PORT/app-debug.apk"
echo ""
echo "Download and tap the downloaded file to install MacDeck!"
echo "Press Ctrl+C to stop the installer server once installed."
echo "=================================================="

cd "$APK_DIR"
python3 -m http.server "$PORT"
