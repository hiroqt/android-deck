#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Building and launching MacDeck macOS Host Agent..."
cd "$ROOT_DIR/macos/MacDeck"
swift run MacDeck
