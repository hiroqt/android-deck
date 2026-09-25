#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 1. Validating Protocol JSON Fixtures ==="
for fixture in "$ROOT_DIR"/protocol/fixtures/*.json; do
    echo "Checking $(basename "$fixture")..."
    python3 -m json.tool "$fixture" > /dev/null
    echo "  ✅ Valid JSON"
done

echo ""
echo "=== 2. Running macOS Swift Unit Tests ==="
cd "$ROOT_DIR/macos/MacDeck"
swift test

echo ""
echo "=== 3. Checking USB helper script permissions ==="
if [[ -x "$ROOT_DIR/scripts/usb/connect.sh" ]]; then
    echo "  ✅ scripts/usb/connect.sh is executable"
else
    echo "  ❌ scripts/usb/connect.sh is not executable"
    exit 1
fi

echo ""
echo "🎉 All Protocol & Host Tests Passed Successfully!"
