#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APK_DIR="$ROOT_DIR/android/app/build/outputs/apk/debug"
APK="$APK_DIR/app-debug.apk"

echo "==> Checking Android APK..."
if [[ ! -f "$APK" || "${1:-}" == "--build" ]]; then
    echo "==> Building fresh Android APK (assembleDebug)..."
    "$ROOT_DIR/android/gradlew" -p "$ROOT_DIR/android" assembleDebug
fi

chmod +x "$SCRIPT_DIR/serve_portal.py"
exec python3 "$SCRIPT_DIR/serve_portal.py"
