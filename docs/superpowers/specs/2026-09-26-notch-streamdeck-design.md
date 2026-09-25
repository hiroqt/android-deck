# MacBook Notch Stream Deck (NotchDeck) - Architectural Design Specification

**Date**: 2026-09-26  
**Status**: Approved  
**Author**: Pair Programming AI & User  

---

## 1. Executive Summary & Goals

**NotchDeck** is a native macOS menu-bar/overlay utility that transforms the MacBook camera notch into an interactive, customizable, fluid **Stream Deck**. 

Key design pillars:
1. **Notch Integration**: Hugs the physical MacBook camera cutout perfectly when collapsed, expanding smoothly downward on click. On non-notch Macs or external monitors, it renders a simulated dynamic notch pill at top-center.
2. **Liquid Glass Aesthetic**: Uses multi-layered frosted glass materials (`NSVisualEffectView`), directional specular rim highlights, subtle inner glow, and ambient backlights to create a high-end Apple-grade liquid glass design.
3. **Modular Stream Deck**: Sits flush at the top of the screen with a 2×5 grid of customizable slots supporting Native App Launchers, Media Controls (Spotify/Apple Music), System Toggles (Mic Mute, Volume, Screen Lock, Screenshot), Shell Scripts, and Web URLs.
4. **Dual Customization**: Inline quick-edit right inside the Notch HUD (swap/reorder slots without leaving the notch) plus a dedicated Settings & Appearance window.

---

## 2. Architecture & Window Management

### 2.1 Lifecycle & Process Configuration
* **Process Type**: Agent / Background app (`LSUIElement = true` in `Info.plist`). Does not take space in the Dock, but stays alive in the background.
* **Status Bar Item**: Compact menu bar extra providing quick access to Preferences, Toggle Deck, and Quit.

### 2.2 Window Architecture (`NotchWindowController`)
* **Window Class**: Subclass of `NSPanel` (`NotchPanel`) with:
  * `level = .statusBar` (floats above standard app windows and fullscreen spaces).
  * `styleMask = [.borderless, .nonactivatingPanel]`.
  * `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]`.
  * `backgroundColor = .clear` and `isOpaque = false`.
  * `hasShadow = false` (shadow is rendered inside SwiftUI to avoid window border clipping).
  * `hidesOnDeactivate = false`.

### 2.3 Screen Geometry & Notch Detection
* **Physical Notch Measurement**:
  ```swift
  let screen = NSScreen.main ?? NSScreen.screens.first!
  let topInset = screen.safeAreaInsets.top
  let hasPhysicalNotch = topInset > 24.0
  ```
* **Alignment**:
  * Horizontally centered: `x = screen.frame.midX - windowWidth / 2`.
  * Vertically anchored: `y = screen.frame.maxY - windowHeight`.
* **Adaptive Sizing**:
  * **Collapsed State**:
    * Width: ~180pt (or physical notch width if available via auxiliary areas).
    * Height: ~34pt (flush with menu bar / hardware bezel).
  * **Expanded State**:
    * Width: 520pt.
    * Height: 172pt.
* **Multi-Display & Screen Change Observation**:
  * Observes `NSApplication.didChangeScreenParametersNotification` to re-anchor when external displays are plugged in or display resolution changes.

### 2.4 Interaction Trigger & Dismissal
* **Expansion Trigger**: Click on the collapsed notch area (`leftMouseDown`).
* **Dismissal Triggers**:
  * Clicking the notch header again.
  * Clicking anywhere outside the window (monitored via `NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown])`).
  * Pressing `Escape`.

---

## 3. Liquid Glass Visuals & Spring Animation System

### 3.1 Visual Layering & Materials
To deliver the authentic "liquid glass" look:
1. **Background Blurring**: AppKit `NSVisualEffectView` bridge with `.hudWindow` material and `.behindWindow` blending mode.
2. **Frosted Glass Shading**: Multi-stop acrylic gradient overlay:
   * Top: `Color(white: 0.08, opacity: 0.78)`
   * Bottom: `Color(white: 0.03, opacity: 0.88)`
3. **Directional Specular Rim**:
   * `1.0pt` inner stroke gradient:
     * Top bevel: `Color.white.opacity(0.45)` (simulating overhead light hitting the top glass curvature).
     * Sides: `Color.white.opacity(0.18)`
     * Bottom: `Color.white.opacity(0.06)`
4. **Specular Inner Glow**: `Color.white.opacity(0.04)` fill with continuous smooth squircle corner radius (`24pt`).
5. **Ambient Dynamic Backlight**: Faint blurred radial background glow responding to the active app or currently playing music album art.

### 3.2 Animation Physics
* **Expansion / Collapse**:
  * Curve: `.interactiveSpring(response: 0.36, dampingFraction: 0.74, blendDuration: 0.12)`.
  * Animates height and width simultaneously, creating an organic fluid droplet expansion effect.
* **Tile Stagger**:
  * When expanding, tiles enter with a 25ms staggered scale (`0.92 -> 1.0`) and fade.
* **Haptic & Tactile Press Feedback**:
  * Hovering: `scaleEffect(1.04)` with brightened rim.
  * Pressing: `scaleEffect(0.95)` with immediate action trigger (<10ms).

---

## 4. Stream Deck Grid, Modular Slots & Actions

### 4.1 Layout Architecture
* **Top Notch Header**:
  * Dynamic status indicator (Now Playing title / mini clock).
  * Quick Edit button (pencil icon) to toggle inline editing.
  * Close / minimize button.
* **Main Action Matrix**:
  * 2 rows × 5 columns (10 slots default).
  * Each tile: `56×56pt` rounded squircle with glass border, icon, and optional badge/label.

### 4.2 Action Types & Payloads
```swift
enum ActionType: String, Codable {
    case appLauncher
    case mediaControl
    case systemToggle
    case shellScript
    case urlBookmark
}

struct DeckSlot: Codable, Identifiable {
    var id: UUID
    var index: Int
    var title: String
    var actionType: ActionType
    var target: String          // Bundle ID, URL, Script command, or Toggle ID
    var iconName: String?       // SF Symbol name or custom icon
    var customColorHex: String? // Optional tint accent
}
```

#### Detailed Action Implementations:
1. **`appLauncher`**:
   * Launches or focuses app using `NSWorkspace.shared.openApplication(at:configuration:)`.
   * Automatically resolves high-resolution macOS icons via `NSWorkspace.shared.icon(forFile:)`.
   * Displays running indicator dot if `NSRunningApplication.runningApplications(withBundleIdentifier:)` is non-empty.
2. **`mediaControl`**:
   * Commands: `playPause`, `nextTrack`, `previousTrack`.
   * Dispatches via AppleScript to Music.app or Spotify.app, or system media key events.
   * Real-time metadata poll: Track title, artist, playback state.
3. **`systemToggle`**:
   * `micMute`: Toggles default audio input volume (`0` vs `100`) via CoreAudio / AppleScript, displaying live green/red indicator.
   * `volumeMute`: Toggles default audio output mute.
   * `screenshot`: Executes `screencapture -i`.
   * `lockScreen`: Dispatches lock screen command.
4. **`shellScript`**:
   * Executes custom bash/zsh command asynchronously via `Process()`.
5. **`urlBookmark`**:
   * Opens URL in user's default browser via `NSWorkspace.shared.open(url)`.

### 4.3 Default Out-of-the-Box Configuration
* **Slot 1**: Finder (`com.apple.finder`)
* **Slot 2**: Safari (`com.apple.Safari`)
* **Slot 3**: Terminal (`com.apple.Terminal`)
* **Slot 4**: Music (`com.apple.Music`)
* **Slot 5**: System Settings (`com.apple.systempreferences`)
* **Slot 6**: Microphone Mute Toggle (Hardware Mic control)
* **Slot 7**: System Volume Mute Toggle
* **Slot 8**: Media Play/Pause
* **Slot 9**: Interactive Screen Capture (`screencapture -i`)
* **Slot 10**: Lock Screen

---

## 5. Customization Engine & Settings Window

### 5.1 Inline HUD Quick-Edit
* Clicking the edit pencil on the notch HUD activates inline edit mode:
  * Tiles glow with edit halos and a small swap badge.
  * Clicking any tile opens an inline glass inspector popover:
    * Select Action Type (App, Media, System, Script, URL).
    * If App: Searchable application picker querying all installed apps.
    * If System: Toggle selector (Mic, Volume, Screenshot, Lock).
    * If Script: Command input field.
    * If URL: URL string input field.
    * SF Symbol picker for custom icons.
  * Reorder via drag or quick-swap.
* Clicking "Done" or `Esc` persists configuration to disk.

### 5.2 Dedicated Settings Window (`NotchSettingsView`)
* Multi-tab macOS Preferences:
  1. **Layout**: Grid dimensions (columns 4–6, rows 1–3), slot manager.
  2. **Liquid Glass Appearance**:
     * Glass blur style (`.ultraThinMaterial`, `.hudWindow`, `.thinMaterial`).
     * Specular highlight intensity slider (0.0 to 1.0).
     * Ambient backlight toggle and color theme.
     * Corner curvature slider (16pt to 32pt).
  3. **General**:
     * Launch at Login.
     * External display simulated notch toggle and pill size.
     * Reset to Defaults.

### 5.3 Storage & Persistence
* Saved at `~/Library/Application Support/NotchDeck/config.json`.
* Atomic writes using `FileManager` with fallback to default configuration on first launch or JSON corruption.

---

## 6. Project Structure & Build Setup

```
NotchDeck/
├── Package.swift / Project configuration
├── Sources/
│   ├── App/
│   │   ├── NotchDeckApp.swift              // App entry point & NSApplicationDelegate
│   │   ├── NotchWindowController.swift     // NSPanel overlay & event monitors
│   │   ├── NotchPanel.swift                // Borderless non-activating NSPanel
│   │   └── AppDelegate.swift               // Status bar item & lifecycle
│   ├── Views/
│   │   ├── NotchDeckRootView.swift         // Top-level SwiftUI morphing container
│   │   ├── CollapsedNotchView.swift        // Sleek closed notch pill
│   │   ├── ExpandedDeckView.swift          // Expanded stream deck grid & header
│   │   ├── LiquidGlassBackground.swift     // Frosted glass, specular rim & ambient glow
│   │   ├── DeckSlotTileView.swift          // Individual interactive slot tile
│   │   ├── InlineSlotEditorSheet.swift     // Quick edit popover
│   │   └── Settings/
│   │       ├── SettingsWindowController.swift
│   │       └── SettingsView.swift
│   ├── Models/
│   │   ├── DeckSlot.swift                  // Slot data model & ActionType enum
│   │   ├── NotchDeckConfig.swift           // App config & appearance settings
│   │   └── InstalledAppInfo.swift          // App metadata model
│   ├── Services/
│   │   ├── ConfigManager.swift             // JSON loading, saving, defaults
│   │   ├── AppScannerService.swift         // Scans /Applications for bundle IDs & icons
│   │   ├── ActionExecutionService.swift    // Dispatches app launch, system toggles, scripts
│   │   ├── MediaControlService.swift       // AppleScript / media keys & now playing query
│   │   └── SystemControlService.swift      // CoreAudio mic/volume toggles & lock screen
│   └── Resources/
│       └── Assets.xcassets
└── Tests/
    └── NotchDeckTests/
        ├── ConfigManagerTests.swift
        ├── ActionExecutionTests.swift
        └── GeometryTests.swift
```

---

## 7. Error Handling & Edge Cases

1. **External Monitor Hotplugging / Resolution Change**:
   * Observes `didChangeScreenParametersNotification`. Recomputes `safeAreaInsets` and animates window position smoothly to the new screen center.
2. **Missing or Deleted Applications**:
   * If an assigned app bundle ID is uninstalled, displays a fallback placeholder icon with a warning badge instead of crashing or failing silently.
3. **Permissions (Automation / AppleScript / Accessibility)**:
   * Graceful fallback if system permissions are not yet granted; prompts the user with clear instructions in Settings.
4. **Multi-Space / Fullscreen App Compatibility**:
   * `.canJoinAllSpaces` and `.fullScreenAuxiliary` collection behavior ensures the notch stream deck remains accessible across all Mission Control virtual desktops and over fullscreen games/apps.

---

## 8. Verification & Testing Plan

1. **Unit Tests (`swift test`)**:
   * Test `ConfigManager` serialization, deserialization, and migration.
   * Test `ActionExecutionService` routing for all 5 action types.
   * Test `ScreenGeometry` calculations for physical notch vs external displays.
2. **Visual & UI Verification**:
   * Verify collapsed notch pill alignment with MacBook camera bezel.
   * Verify smooth 60fps spring animation during expansion and collapse.
   * Verify liquid glass specular highlight rim and blur refraction over dark and light desktop wallpapers.
   * Verify click-to-expand and click-outside dismissal.
   * Verify inline edit mode (modifying a slot and checking live persistence).
