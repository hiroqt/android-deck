#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Building NotchDeck (macOS Native Liquid Glass Notch Stream Deck)..."
cd "$ROOT_DIR/macos/NotchDeck"
swift build -c release

echo "==> Launching NotchDeck..."
"$ROOT_DIR/macos/NotchDeck/.build/release/NotchDeck" "$@"
