# MacDeck

Turn your Android phone into a dedicated touchscreen Stream Deck for macOS.

## Key Features

- **Full-Screen Adaptive UI (Max 6 Apps)**: Auto-adapts between **Portrait (2×3)** and **Landscape (3×2)** with large, responsive touch targets designed for fast, accurate taps.
- **Genuine macOS App Icons**: macOS host extracts native app icons via `NSWorkspace` and transmits them directly to your phone.
- **Dynamic App Customization**: Pick and swap any of the 6 slots from installed Mac applications; updates appear live on Android without restarting.
- **Zero-Latency USB & LAN Wi-Fi**: Instant USB connectivity via ADB TCP reverse tunnel (`./scripts/usb/connect.sh`) plus Wi-Fi LAN fallback.
- **Instant Tactile Feedback**: Haptic pulse and visual compression on pointer down (<16ms) before network confirmation.
- **Secure by Design**: Android only sends abstract action IDs (`app-1`, `app-2`); the Mac retains full authority over executable paths and permissions.

---

## Quickstart

### 1. Start the Mac Host Agent
```bash
./scripts/run_mac.sh
```
The server will start listening on port `8765` and display your local LAN IP addresses as well as the active 6 app slots.

### 2. Connect via USB (Recommended)
1. Plug your Android phone into your Mac via USB cable (ensure **USB Debugging** is enabled in Developer Options).
2. Run the ADB reverse tunnel helper:
   ```bash
   ./scripts/usb/connect.sh
   ```
3. Install and launch the Android client:
   ```bash
   ./scripts/install_android.sh
   ```
4. On your phone, tap **Connect via USB** (points to `ws://127.0.0.1:8765`).

### 3. Connect via Wi-Fi (LAN)
1. Ensure your Mac and Android phone are on the same Wi-Fi network.
2. In the Android app, tap the top connection bar or gear icon.
3. Select **LAN (Wi-Fi)**, enter your Mac's IP (displayed in the Mac terminal output), and tap **Connect via Wi-Fi**.

---

## Customizing Your 6 Apps

In the running MacDeck terminal, you can interactively manage your deck:
- `list` — View currently assigned apps for all 6 slots.
- `scan` — Scan and list all installed applications on your Mac.
- `set <slot 1-6> <bundleId>` — Assign an app to a slot (e.g. `set 3 com.brave.Browser`). The update broadcasts immediately to your Android screen!
- `launch <slot 1-6>` — Test-launch any app directly from the Mac host.

---

## Architecture & Documentation

Comprehensive architectural design and engineering specifications are located in [`docs/`](docs/):
- [`docs/agents.md`](docs/agents.md) — Coding agent invariants and rules.
- [`docs/prd.md`](docs/prd.md) — Product requirements document.
- [`docs/architecture.md`](docs/architecture.md) — System architecture, security boundaries, and protocol flow.
- [`docs/design.md`](docs/design.md) — Interaction design and adaptive UI specifications.
- [`docs/implementation-plan.md`](docs/implementation-plan.md) — Multi-phase delivery roadmap.
- [`protocol/protocol.md`](protocol/protocol.md) — Formal WebSocket JSON wire specification.

---

## Verification & Testing

Run all unit tests and protocol validations:
```bash
# Validate protocol fixtures, scripts, and macOS Swift tests
./scripts/test_protocol.sh

# Run Android unit tests
cd android && ./gradlew test
```
