# MacDeck & NotchDeck

A high-performance macOS desktop productivity suite providing both physical display notch integration (**NotchDeck**) and an Android touchscreen stream deck (**MacDeck**).

---

## NotchDeck (macOS Native Liquid Glass Notch Stream Deck)

**NotchDeck** transforms the MacBook camera notch (or simulated top-bar notch on external displays) into an interactive, fluid Liquid Glass HUD housing a 10-slot (2×5) quick-action Stream Deck.

![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![Tests](https://img.shields.io/badge/tests-35%20passing-brightgreen)

### Key Features

- **Fluid Dynamic Island / Liquid Glass HUD**: Anchors directly below or behind the physical MacBook display notch (with automatic hardware notch detection via `safeAreaInsets` or fallback top-bar pill on non-notched external screens).
- **10 Interactive Action Slots (2×5 Grid)**: Fast tactile execution with visual compression feedback and configurable SF Symbol icons and custom accent colors.
- **5 Action Types Supported**:
  1. **System Controls**: Volume Up / Down / Mute, Brightness Up / Down, Play / Pause media playback, Lock Screen, Screenshot.
  2. **App Launcher**: Instant launch or focus of any installed application using `NSWorkspace`.
  3. **Apple Shortcuts**: Trigger macOS Siri Shortcuts via `shortcuts run <name>`.
  4. **URL Bookmarks**: Direct browser navigation to bookmarks or custom URL schemes.
  5. **Shell Scripts**: Securely execute custom bash/zsh scripts and commands.
- **Interactive Expand & Collapse**:
  - Hover or trigger via hotkey (`⌘D`) to smoothly expand from compact notch pill (180×32pt) to full HUD (520×172pt) with spring damping physics.
  - Auto-collapses on outside click, mouse departure, or Escape key.
- **Inline Live Slot Editor**: Right-click or gear icon on any tile opens an inline editor sheet to customize title, icon, action type, color, and target (with instant search across all installed Mac applications).
- **Preferences & Customization**: Configure glass material, blur radius, tint color, background opacity, and animation physics.
- **Robust Persistence**: Settings and slot configurations are saved atomically to `~/Library/Application Support/NotchDeck/config.json`.
- **Status Bar Companion**: Non-activating `NSPanel` floating at `.statusBar` level across all macOS spaces and full-screen apps, accompanied by a lightweight menu bar item.

### NotchDeck Quickstart

Launch NotchDeck in release mode with one command:
```bash
./scripts/run_notchdeck.sh
```

Or build and run manually via Swift Package Manager:
```bash
cd macos/NotchDeck
swift build -c release
./.build/release/NotchDeck
```

### Shortcuts & Controls

- **`⌘D`**: Toggle NotchDeck expand / collapse.
- **`⌘,`**: Open NotchDeck Preferences & Glass Customization.
- **`⌘Q`**: Quit NotchDeck.
- **Click outside / `Esc`**: Collapse HUD back into the notch.
- **Right-click tile** or **Hover + Gear**: Open inline slot editor.

### Running NotchDeck Tests

```bash
cd macos/NotchDeck
swift test
```

---

## MacDeck (Android Touchscreen Stream Deck)

Turn your Android phone into a dedicated touchscreen Stream Deck for macOS over USB or Wi-Fi.

### Key Features

- **Full-Screen Adaptive UI (Max 6 Apps)**: Auto-adapts between **Portrait (2×3)** and **Landscape (3×2)** with large, responsive touch targets designed for fast, accurate taps.
- **Genuine macOS App Icons**: macOS host extracts native app icons via `NSWorkspace` and transmits them directly to your phone.
- **Dynamic App Customization**: Pick and swap any of the 6 slots from installed Mac applications; updates appear live on Android without restarting.
- **Zero-Latency USB & LAN Wi-Fi**: Instant USB connectivity via ADB TCP reverse tunnel (`./scripts/usb/connect.sh`) plus Wi-Fi LAN fallback.
- **Instant Tactile Feedback**: Haptic pulse and visual compression on pointer down (<16ms) before network confirmation.
- **Secure by Design**: Android only sends abstract action IDs (`app-1`, `app-2`); the Mac retains full authority over executable paths and permissions.

### Quickstart

#### 1. Start the Mac Host Agent
```bash
./scripts/run_mac.sh
```
The server will start listening on port `8765` and display your local LAN IP addresses as well as the active 6 app slots.

#### 2. Connect via USB (Recommended)
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

#### 3. Connect via Wi-Fi (LAN)
1. Ensure your Mac and Android phone are on the same Wi-Fi network.
2. In the Android app, tap the top connection bar or gear icon.
3. Select **LAN (Wi-Fi)**, enter your Mac's IP (displayed in the Mac terminal output), and tap **Connect via Wi-Fi**.

### Customizing Your 6 Apps (MacDeck)

In the running MacDeck terminal, you can interactively manage your deck:
- `list` — View currently assigned apps for all 6 slots.
- `scan` — Scan and list all installed applications on your Mac.
- `set <slot 1-6> <bundleId>` — Assign an app to a slot (e.g. `set 3 com.brave.Browser`). The update broadcasts immediately to your Android screen!
- `launch <slot 1-6>` — Test-launch any app directly from the Mac host.

---

## Architecture & Documentation

Comprehensive architectural design and engineering specifications are located in [`docs/`](docs/):

### NotchDeck Specifications
- [`docs/superpowers/specs/2026-09-26-notch-streamdeck-design.md`](docs/superpowers/specs/2026-09-26-notch-streamdeck-design.md) — Comprehensive technical design document for NotchDeck.
- [`docs/superpowers/plans/2026-09-26-notch-streamdeck.md`](docs/superpowers/plans/2026-09-26-notch-streamdeck.md) — Multi-task implementation and testing plan.

### MacDeck Specifications
- [`docs/agents.md`](docs/agents.md) — Coding agent invariants and rules.
- [`docs/prd.md`](docs/prd.md) — Product requirements document.
- [`docs/architecture.md`](docs/architecture.md) — System architecture, security boundaries, and protocol flow.
- [`docs/design.md`](docs/design.md) — Interaction design and adaptive UI specifications.
- [`docs/implementation-plan.md`](docs/implementation-plan.md) — Multi-phase delivery roadmap.
- [`protocol/protocol.md`](protocol/protocol.md) — Formal WebSocket JSON wire specification.

---

## Verification & Testing Suite

Run all unit tests, protocol validations, and compilation checks across the entire repository:

```bash
# 1. NotchDeck macOS Swift unit tests (35 tests)
cd macos/NotchDeck && swift test

# 2. NotchDeck Release binary build
cd macos/NotchDeck && swift build -c release

# 3. MacDeck protocol fixtures, scripts, and macOS host tests
./scripts/test_protocol.sh

# 4. Android unit tests
cd android && ./gradlew test
```
