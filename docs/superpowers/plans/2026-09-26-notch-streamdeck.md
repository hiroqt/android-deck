# MacBook Notch Stream Deck (NotchDeck) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS desktop application (`NotchDeck`) that hugs the MacBook camera notch (with simulated dynamic notch fallback on external screens), featuring a customizable 10-slot Stream Deck with a polished liquid glass aesthetic, fluid spring expansion on click, and dual inline/settings customization.

**Architecture:** AppKit `NSPanel` overlay operating at `.statusBar` level with `.canJoinAllSpaces` and non-activating window mask hosting a pure SwiftUI UI layer. Background blur via `NSVisualEffectView` combined with custom multi-stop acrylic gradient and directional specular highlight rim shaders for the liquid glass effect. Core services handle app scanning, audio input/output controls, media playback commands, shell execution, and persistent JSON configuration.

**Tech Stack:** Swift 6.0+, macOS 14.0+ SDK (AppKit, SwiftUI, CoreAudio, NSWorkspace), Swift Package Manager (SPM).

**Spec:** [`docs/superpowers/specs/2026-09-26-notch-streamdeck-design.md`](file:///Users/arnel/android-deck/docs/superpowers/specs/2026-09-26-notch-streamdeck-design.md)

## Global Constraints
- Target platform: macOS 14.0+ (`arm64` Apple Silicon and `x86_64` Intel).
- UI Framework: SwiftUI wrapped inside AppKit borderless `NSPanel`.
- Process Behavior: Agent mode (`LSUIElement = true`), runs silently in background with status bar menu item.
- Zero external package dependencies (uses 100% native Apple SDKs).
- Animation curves: `.interactiveSpring(response: 0.36, dampingFraction: 0.74, blendDuration: 0.12)`.
- Expansion trigger: Click on collapsed notch pill. Dismissal trigger: Click notch header, outside click, or `Escape` key.
- Storage path: `~/Library/Application Support/NotchDeck/config.json`.

---

## File Structure

```
macos/NotchDeck/
├── Package.swift
├── Sources/
│   └── NotchDeck/
│       ├── Models/
│       │   ├── ActionType.swift
│       │   ├── DeckSlot.swift
│       │   ├── NotchDeckConfig.swift
│       │   ├── GlassAppearanceSettings.swift
│       │   └── ScreenGeometry.swift
│       ├── Services/
│       │   ├── ConfigManager.swift
│       │   ├── AppScannerService.swift
│       │   ├── SystemControlService.swift
│       │   ├── MediaControlService.swift
│       │   └── ActionExecutionService.swift
│       ├── Views/
│       │   ├── LiquidGlassBackground.swift
│       │   ├── DeckSlotTileView.swift
│       │   ├── CollapsedNotchView.swift
│       │   ├── ExpandedDeckView.swift
│       │   ├── InlineSlotEditorSheet.swift
│       │   ├── NotchDeckRootView.swift
│       │   └── Settings/
│       │       └── SettingsView.swift
│       └── App/
│           ├── NotchPanel.swift
│           ├── NotchWindowController.swift
│           ├── AppDelegate.swift
│           └── NotchDeckApp.swift
└── Tests/
    └── NotchDeckTests/
        ├── ModelsTests.swift
        ├── ConfigManagerTests.swift
        ├── ActionExecutionTests.swift
        └── ScreenGeometryTests.swift
```

---

### Task 1: Project Setup & Core Data Models

**Files:**
- Create: `macos/NotchDeck/Package.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/Models/ActionType.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/Models/DeckSlot.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/Models/GlassAppearanceSettings.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/Models/NotchDeckConfig.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/Models/ScreenGeometry.swift`
- Test: `macos/NotchDeck/Tests/NotchDeckTests/ModelsTests.swift`

**Interfaces:**
- Consumes: None (base models)
- Produces: `ActionType`, `DeckSlot`, `GlassAppearanceSettings`, `NotchDeckConfig`, `ScreenGeometry`

- [ ] **Step 1: Create `Package.swift`**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotchDeck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "NotchDeck",
            targets: ["NotchDeck"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "NotchDeck",
            dependencies: [],
            path: "Sources/NotchDeck"
        ),
        .testTarget(
            name: "NotchDeckTests",
            dependencies: ["NotchDeck"],
            path: "Tests/NotchDeckTests"
        )
    ]
)
```

- [ ] **Step 2: Write failing unit tests for models (`ModelsTests.swift`)**

```swift
import XCTest
@testable import NotchDeck

final class ModelsTests: XCTestCase {
    func testDeckSlotDefaultEncodingAndDecoding() throws {
        let slot = DeckSlot(
            id: UUID(),
            index: 0,
            title: "Safari",
            actionType: .appLauncher,
            target: "com.apple.Safari",
            iconName: "safari.fill"
        )
        let data = try JSONEncoder().encode(slot)
        let decoded = try JSONDecoder().decode(DeckSlot.self, from: data)
        XCTAssertEqual(decoded.title, "Safari")
        XCTAssertEqual(decoded.actionType, .appLauncher)
        XCTAssertEqual(decoded.target, "com.apple.Safari")
    }

    func testDefaultConfigContainsTenSlots() {
        let config = NotchDeckConfig.defaultConfig()
        XCTAssertEqual(config.slots.count, 10)
        XCTAssertEqual(config.gridColumns, 5)
        XCTAssertEqual(config.gridRows, 2)
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd macos/NotchDeck && swift test`
Expected: FAIL (types not defined yet)

- [ ] **Step 4: Implement core model types**

`ActionType.swift`:
```swift
import Foundation

public enum ActionType: String, Codable, CaseIterable {
    case appLauncher
    case mediaControl
    case systemToggle
    case shellScript
    case urlBookmark
}
```

`DeckSlot.swift`:
```swift
import Foundation

public struct DeckSlot: Codable, Identifiable, Equatable {
    public var id: UUID
    public var index: Int
    public var title: String
    public var actionType: ActionType
    public var target: String
    public var iconName: String?
    public var customColorHex: String?

    public init(
        id: UUID = UUID(),
        index: Int,
        title: String,
        actionType: ActionType,
        target: String,
        iconName: String? = nil,
        customColorHex: String? = nil
    ) {
        self.id = id
        self.index = index
        self.title = title
        self.actionType = actionType
        self.target = target
        self.iconName = iconName
        self.customColorHex = customColorHex
    }
}
```

`GlassAppearanceSettings.swift`:
```swift
import Foundation

public struct GlassAppearanceSettings: Codable, Equatable {
    public var blurMaterial: String // "hud", "ultraThin", "thin"
    public var specularIntensity: Double // 0.0 ... 1.0
    public var ambientBacklightEnabled: Bool
    public var cornerRadius: Double

    public init(
        blurMaterial: String = "hud",
        specularIntensity: Double = 0.45,
        ambientBacklightEnabled: Bool = true,
        cornerRadius: Double = 24.0
    ) {
        self.blurMaterial = blurMaterial
        self.specularIntensity = specularIntensity
        self.ambientBacklightEnabled = ambientBacklightEnabled
        self.cornerRadius = cornerRadius
    }
}
```

`NotchDeckConfig.swift`:
```swift
import Foundation

public struct NotchDeckConfig: Codable, Equatable {
    public var gridColumns: Int
    public var gridRows: Int
    public var slots: [DeckSlot]
    public var appearance: GlassAppearanceSettings

    public init(
        gridColumns: Int = 5,
        gridRows: Int = 2,
        slots: [DeckSlot] = [],
        appearance: GlassAppearanceSettings = GlassAppearanceSettings()
    ) {
        self.gridColumns = gridColumns
        self.gridRows = gridRows
        self.slots = slots
        self.appearance = appearance
    }

    public static func defaultConfig() -> NotchDeckConfig {
        let defaultSlots: [DeckSlot] = [
            DeckSlot(index: 0, title: "Finder", actionType: .appLauncher, target: "com.apple.finder", iconName: "folder.fill"),
            DeckSlot(index: 1, title: "Safari", actionType: .appLauncher, target: "com.apple.Safari", iconName: "safari.fill"),
            DeckSlot(index: 2, title: "Terminal", actionType: .appLauncher, target: "com.apple.Terminal", iconName: "terminal.fill"),
            DeckSlot(index: 3, title: "Music", actionType: .appLauncher, target: "com.apple.Music", iconName: "music.note"),
            DeckSlot(index: 4, title: "Settings", actionType: .appLauncher, target: "com.apple.systempreferences", iconName: "gearshape.fill"),
            DeckSlot(index: 5, title: "Mic Mute", actionType: .systemToggle, target: "micMute", iconName: "mic.fill"),
            DeckSlot(index: 6, title: "Vol Mute", actionType: .systemToggle, target: "volumeMute", iconName: "speaker.slash.fill"),
            DeckSlot(index: 7, title: "Play/Pause", actionType: .mediaControl, target: "playPause", iconName: "playpause.fill"),
            DeckSlot(index: 8, title: "Screenshot", actionType: .systemToggle, target: "screenshot", iconName: "camera.fill"),
            DeckSlot(index: 9, title: "Lock", actionType: .systemToggle, target: "lockScreen", iconName: "lock.fill")
        ]
        return NotchDeckConfig(gridColumns: 5, gridRows: 2, slots: defaultSlots, appearance: GlassAppearanceSettings())
    }
}
```

`ScreenGeometry.swift`:
```swift
import Foundation

public struct ScreenGeometry: Equatable {
    public var screenWidth: CGFloat
    public var screenHeight: CGFloat
    public var topSafeAreaInset: CGFloat
    public var hasPhysicalNotch: Bool

    public init(screenWidth: CGFloat, screenHeight: CGFloat, topSafeAreaInset: CGFloat) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.topSafeAreaInset = topSafeAreaInset
        self.hasPhysicalNotch = topSafeAreaInset > 24.0
    }

    public var notchCollapsedSize: CGSize {
        if hasPhysicalNotch {
            return CGSize(width: 180, height: max(32, topSafeAreaInset))
        } else {
            return CGSize(width: 180, height: 34)
        }
    }

    public var notchExpandedSize: CGSize {
        return CGSize(width: 520, height: 172)
    }
}
```

- [ ] **Step 5: Run tests and verify they pass**

Run: `cd macos/NotchDeck && swift test`
Expected: PASS with 2 passed tests.

- [ ] **Step 6: Commit**

```bash
git add macos/NotchDeck/
git commit -m "feat(notchdeck): add Package.swift and core data models"
```

---

### Task 2: Persistence & Configuration Manager

**Files:**
- Create: `macos/NotchDeck/Sources/NotchDeck/Services/ConfigManager.swift`
- Test: `macos/NotchDeck/Tests/NotchDeckTests/ConfigManagerTests.swift`

**Interfaces:**
- Consumes: `NotchDeckConfig`, `DeckSlot`, `GlassAppearanceSettings`
- Produces: `ConfigManagerProtocol`, `ConfigManager` with `loadConfig()`, `saveConfig(_:)`, `updateSlot(_:)`, `resetToDefault()`

- [ ] **Step 1: Write failing unit test for `ConfigManager`**

```swift
import XCTest
@testable import NotchDeck

final class ConfigManagerTests: XCTestCase {
    var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testConfigManagerLoadsDefaultWhenNoFileExists() {
        let configFile = tempDirectory.appendingPathComponent("config.json")
        let manager = ConfigManager(fileURL: configFile)
        let config = manager.loadConfig()
        XCTAssertEqual(config.slots.count, 10)
    }

    func testConfigManagerSavesAndReloadsConfig() throws {
        let configFile = tempDirectory.appendingPathComponent("config.json")
        let manager = ConfigManager(fileURL: configFile)
        var config = manager.loadConfig()
        config.slots[0].title = "Custom Finder"
        try manager.saveConfig(config)

        let reloaded = manager.loadConfig()
        XCTAssertEqual(reloaded.slots[0].title, "Custom Finder")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd macos/NotchDeck && swift test --filter ConfigManagerTests`
Expected: FAIL (`ConfigManager` not defined)

- [ ] **Step 3: Implement `ConfigManager`**

`ConfigManager.swift`:
```swift
import Foundation

public final class ConfigManager: ObservableObject {
    public static let shared = ConfigManager()
    
    private let fileURL: URL
    @Published public private(set) var config: NotchDeckConfig

    public init(fileURL: URL? = nil) {
        if let fileURL = fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent("NotchDeck", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent("config.json")
        }
        self.config = NotchDeckConfig.defaultConfig()
        self.config = loadConfig()
    }

    public func loadConfig() -> NotchDeckConfig {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let fallback = NotchDeckConfig.defaultConfig()
            try? saveConfig(fallback)
            return fallback
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let loaded = try JSONDecoder().decode(NotchDeckConfig.self, from: data)
            DispatchQueue.main.async { self.config = loaded }
            return loaded
        } catch {
            let fallback = NotchDeckConfig.defaultConfig()
            try? saveConfig(fallback)
            return fallback
        }
    }

    public func saveConfig(_ newConfig: NotchDeckConfig) throws {
        let parentDir = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(newConfig)
        try data.write(to: fileURL, options: .atomic)
        DispatchQueue.main.async {
            self.config = newConfig
        }
    }

    public func updateSlot(_ slot: DeckSlot) {
        var current = config
        if let idx = current.slots.firstIndex(where: { $0.id == slot.id || $0.index == slot.index }) {
            current.slots[idx] = slot
            try? saveConfig(current)
        }
    }

    public func resetToDefault() {
        let defaultConfig = NotchDeckConfig.defaultConfig()
        try? saveConfig(defaultConfig)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd macos/NotchDeck && swift test --filter ConfigManagerTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add macos/NotchDeck/Sources/NotchDeck/Services/ConfigManager.swift macos/NotchDeck/Tests/NotchDeckTests/ConfigManagerTests.swift
git commit -m "feat(notchdeck): implement ConfigManager persistence with tests"
```

---

### Task 3: Core Services & Action Execution Engine

**Files:**
- Create: `macos/NotchDeck/Sources/NotchDeck/Services/AppScannerService.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/Services/SystemControlService.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/Services/MediaControlService.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/Services/ActionExecutionService.swift`
- Test: `macos/NotchDeck/Tests/NotchDeckTests/ActionExecutionTests.swift`

**Interfaces:**
- Consumes: `DeckSlot`, `ActionType`
- Produces: `AppScannerService.scanInstalledApps()`, `SystemControlService.toggleMicMute()`, `MediaControlService.playPause()`, `ActionExecutionService.execute(slot:)`

- [ ] **Step 1: Write failing unit tests for `ActionExecutionService`**

```swift
import XCTest
@testable import NotchDeck

final class ActionExecutionTests: XCTestCase {
    func testActionRouterHandlesUnknownTargetGracefully() {
        let service = ActionExecutionService()
        let slot = DeckSlot(index: 0, title: "Invalid", actionType: .systemToggle, target: "nonExistentAction")
        let result = service.execute(slot: slot)
        XCTAssertFalse(result)
    }

    func testAppScannerFindsSystemApps() {
        let scanner = AppScannerService()
        let apps = scanner.scanInstalledApps()
        XCTAssertFalse(apps.isEmpty)
        XCTAssertTrue(apps.contains { $0.bundleIdentifier == "com.apple.finder" || $0.bundleIdentifier == "com.apple.Safari" })
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd macos/NotchDeck && swift test --filter ActionExecutionTests`
Expected: FAIL (types not defined)

- [ ] **Step 3: Implement Services**

`AppScannerService.swift`:
```swift
import AppKit

public struct InstalledAppInfo: Identifiable, Equatable {
    public var id: String { bundleIdentifier }
    public let name: String
    public let bundleIdentifier: String
    public let path: String
    public let icon: NSImage?
}

public final class AppScannerService {
    public static let shared = AppScannerService()

    public init() {}

    public func scanInstalledApps() -> [InstalledAppInfo] {
        let searchDirectories = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSHomeDirectory() + "/Applications"
        ]

        var results: [InstalledAppInfo] = []
        var seenBundleIds = Set<String>()

        for dir in searchDirectories {
            guard let items = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for item in items where item.hasSuffix(".app") {
                let fullPath = (dir as NSString).appendingPathComponent(item)
                guard let bundle = Bundle(path: fullPath),
                      let bundleId = bundle.bundleIdentifier else { continue }
                if seenBundleIds.contains(bundleId) { continue }
                seenBundleIds.insert(bundleId)

                let name = bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? bundle.infoDictionary?["CFBundleName"] as? String
                    ?? (item as NSString).deletingPathExtension
                let icon = NSWorkspace.shared.icon(forFile: fullPath)
                results.append(InstalledAppInfo(name: name, bundleIdentifier: bundleId, path: fullPath, icon: icon))
            }
        }
        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
```

`SystemControlService.swift`:
```swift
import Foundation
import AppKit

public final class SystemControlService {
    public static let shared = SystemControlService()

    public init() {}

    public func isMicMuted() -> Bool {
        let script = "input volume of (get volume settings)"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let output = appleScript.executeAndReturnError(&error)
            return output.int32Value == 0
        }
        return false
    }

    @discardableResult
    public func toggleMicMute() -> Bool {
        let script = """
        set curVol to input volume of (get volume settings)
        if curVol is 0 then
            set volume input volume 75
            return false
        else
            set volume input volume 0
            return true
        end if
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let output = appleScript.executeAndReturnError(&error)
            return output.booleanValue
        }
        return false
    }

    public func toggleVolumeMute() {
        let script = "set volume output muted not (output muted of (get volume settings))"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    public func captureInteractiveScreenshot() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-c"] // Interactive capture to clipboard
        try? process.run()
    }

    public func lockScreen() {
        let script = """
        tell application "System Events" to sleep
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
```

`MediaControlService.swift`:
```swift
import Foundation
import AppKit

public final class MediaControlService {
    public static let shared = MediaControlService()

    public init() {}

    public func playPause() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to playpause
        else if application "Music" is running then
            tell application "Music" to playpause
        else
            tell application "Music" to activate
        end if
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    public func nextTrack() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to next track
        else if application "Music" is running then
            tell application "Music" to next track
        end if
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    public func previousTrack() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to previous track
        else if application "Music" is running then
            tell application "Music" to previous track
        end if
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
```

`ActionExecutionService.swift`:
```swift
import Foundation
import AppKit

public final class ActionExecutionService {
    public static let shared = ActionExecutionService()

    private let appScanner: AppScannerService
    private let systemControl: SystemControlService
    private let mediaControl: MediaControlService

    public init(
        appScanner: AppScannerService = .shared,
        systemControl: SystemControlService = .shared,
        mediaControl: MediaControlService = .shared
    ) {
        self.appScanner = appScanner
        self.systemControl = systemControl
        self.mediaControl = mediaControl
    }

    @discardableResult
    public func execute(slot: DeckSlot) -> Bool {
        switch slot.actionType {
        case .appLauncher:
            return launchApp(bundleId: slot.target)
        case .mediaControl:
            return handleMedia(command: slot.target)
        case .systemToggle:
            return handleSystemToggle(toggle: slot.target)
        case .shellScript:
            return executeShell(command: slot.target)
        case .urlBookmark:
            return openURL(urlString: slot.target)
        }
    }

    private func launchApp(bundleId: String) -> Bool {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
            return true
        }
        return false
    }

    private func handleMedia(command: String) -> Bool {
        switch command {
        case "playPause":
            mediaControl.playPause()
            return true
        case "nextTrack":
            mediaControl.nextTrack()
            return true
        case "previousTrack":
            mediaControl.previousTrack()
            return true
        default:
            return false
        }
    }

    private func handleSystemToggle(toggle: String) -> Bool {
        switch toggle {
        case "micMute":
            systemControl.toggleMicMute()
            return true
        case "volumeMute":
            systemControl.toggleVolumeMute()
            return true
        case "screenshot":
            systemControl.captureInteractiveScreenshot()
            return true
        case "lockScreen":
            systemControl.lockScreen()
            return true
        default:
            return false
        }
    }

    private func executeShell(command: String) -> Bool {
        guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        do {
            try process.run()
            return true
        } catch {
            return false
        }
    }

    private func openURL(urlString: String) -> Bool {
        guard let url = URL(string: urlString), NSWorkspace.shared.open(url) else { return false }
        return true
    }
}
```

- [ ] **Step 4: Run tests and verify they pass**

Run: `cd macos/NotchDeck && swift test --filter ActionExecutionTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add macos/NotchDeck/Sources/NotchDeck/Services/
git commit -m "feat(notchdeck): implement core services and action execution engine"
```

---

### Task 4: Liquid Glass Visual Design System

**Files:**
- Create: `macos/NotchDeck/Sources/NotchDeck/Views/LiquidGlassBackground.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/Views/DeckSlotTileView.swift`

**Interfaces:**
- Consumes: `GlassAppearanceSettings`, `DeckSlot`, `ActionExecutionService`
- Produces: `LiquidGlassBackground`, `DeckSlotTileView` with hover/press haptics, specular highlights, and app icons

- [ ] **Step 1: Implement `LiquidGlassBackground.swift`**

```swift
import SwiftUI
import AppKit

public struct VisualEffectView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public init(material: NSVisualEffectView.Material = .hudWindow, blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

public struct LiquidGlassBackground: View {
    public let cornerRadius: CGFloat
    public let specularIntensity: Double
    public let isExpanded: Bool

    public init(cornerRadius: CGFloat = 24.0, specularIntensity: Double = 0.45, isExpanded: Bool = true) {
        self.cornerRadius = cornerRadius
        self.specularIntensity = specularIntensity
        self.isExpanded = isExpanded
    }

    public var body: some View {
        ZStack {
            // Frosted blur
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            // Dark acrylic tint gradient
            LinearGradient(
                colors: [
                    Color(white: 0.08, opacity: 0.85),
                    Color(white: 0.03, opacity: 0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            // Ambient inner glow
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.03))

            // Directional Specular Reflection Rim
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(specularIntensity), location: 0.0),
                            .init(color: Color.white.opacity(specularIntensity * 0.4), location: 0.3),
                            .init(color: Color.white.opacity(0.08), location: 0.7),
                            .init(color: Color.white.opacity(0.02), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.0
                )
        }
        .shadow(color: Color.black.opacity(isExpanded ? 0.45 : 0.2), radius: isExpanded ? 24 : 8, y: isExpanded ? 8 : 2)
    }
}
```

- [ ] **Step 2: Implement `DeckSlotTileView.swift`**

```swift
import SwiftUI
import AppKit

public struct DeckSlotTileView: View {
    public let slot: DeckSlot
    public let isEditing: Bool
    public let onSelect: () -> Void
    public let onEdit: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var appIcon: NSImage? = nil

    public init(
        slot: DeckSlot,
        isEditing: Bool = false,
        onSelect: @escaping () -> Void,
        onEdit: @escaping () -> Void
    ) {
        self.slot = slot
        self.isEditing = isEditing
        self.onSelect = onSelect
        self.onEdit = onEdit
    }

    public var body: some View {
        Button(action: {
            if isEditing {
                onEdit()
            } else {
                onSelect()
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // Glass tile backing
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            isPressed
                                ? Color.white.opacity(0.2)
                                : (isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    isEditing
                                        ? Color.cyan.opacity(0.8)
                                        : (isHovered ? Color.white.opacity(0.3) : Color.white.opacity(0.1)),
                                    lineWidth: isEditing ? 1.5 : 1.0
                                )
                        )
                        .frame(width: 54, height: 54)

                    // Icon
                    if slot.actionType == .appLauncher, let icon = appIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                    } else if let iconName = slot.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(iconColor)
                    } else {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }

                    // Edit indicator badge
                    if isEditing {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.cyan)
                                    .background(Circle().fill(Color.black))
                                    .offset(x: 4, y: -4)
                            }
                            Spacer()
                        }
                        .frame(width: 54, height: 54)
                    }
                }

                Text(slot.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isHovered ? .white : Color(white: 0.8))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: 60)
            }
            .scaleEffect(isPressed ? 0.94 : (isHovered ? 1.05 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .onAppear { loadAppIconIfNeeded() }
        .onChange(of: slot.target) { _ in loadAppIconIfNeeded() }
    }

    private var iconColor: Color {
        if slot.actionType == .systemToggle && slot.target == "micMute" {
            return SystemControlService.shared.isMicMuted() ? .red : .green
        }
        return .white
    }

    private func loadAppIconIfNeeded() {
        if slot.actionType == .appLauncher {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: slot.target) {
                self.appIcon = NSWorkspace.shared.icon(forFile: url.path)
            }
        }
    }
}
```

- [ ] **Step 3: Build to verify compilation**

Run: `cd macos/NotchDeck && swift build`
Expected: Build complete with 0 errors.

- [ ] **Step 4: Commit**

```bash
git add macos/NotchDeck/Sources/NotchDeck/Views/
git commit -m "feat(notchdeck): add liquid glass background and slot tile views"
```

---

### Task 5: Interactive Notch Views & Spring Animations

**Files:**
- Create: `macos/NotchDeck/Sources/NotchDeck/Views/CollapsedNotchView.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/Views/ExpandedDeckView.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/Views/NotchDeckRootView.swift`

**Interfaces:**
- Consumes: `LiquidGlassBackground`, `DeckSlotTileView`, `ConfigManager`, `ActionExecutionService`
- Produces: `NotchDeckRootView` with fluid expansion from collapsed notch pill to 10-slot deck

- [ ] **Step 1: Implement `CollapsedNotchView.swift`**

```swift
import SwiftUI

public struct CollapsedNotchView: View {
    public let hasPhysicalNotch: Bool
    public let onExpand: () -> Void

    @State private var isHovered = false

    public var body: some View {
        Button(action: onExpand) {
            ZStack {
                LiquidGlassBackground(
                    cornerRadius: hasPhysicalNotch ? 12 : 16,
                    specularIntensity: isHovered ? 0.6 : 0.35,
                    isExpanded: false
                )

                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)

                    Text("Deck")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))

                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 180, height: 32)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
```

- [ ] **Step 2: Implement `ExpandedDeckView.swift`**

```swift
import SwiftUI

public struct ExpandedDeckView: View {
    @ObservedObject var configManager: ConfigManager
    public let onCollapse: () -> Void
    public let onOpenSettings: () -> Void
    public let onEditSlot: (DeckSlot) -> Void

    @State private var isEditing = false

    private let columns = [
        GridItem(.adaptive(minimum: 64, maximum: 72), spacing: 10)
    ]

    public var body: some View {
        VStack(spacing: 12) {
            // Header bar
            HStack {
                // Status / Brand
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("NOTCH DECK")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.8))
                }

                Spacer()

                // Edit mode toggle
                Button(action: { withAnimation { isEditing.toggle() } }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                        .font(.system(size: 15))
                        .foregroundColor(isEditing ? .green : .white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(isEditing ? "Done editing" : "Edit slots")

                // Open Settings
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Settings")

                // Collapse button
                Button(action: onCollapse) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Collapse")
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Slot Matrix Grid
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(68), spacing: 8), count: configManager.config.gridColumns), spacing: 10) {
                ForEach(configManager.config.slots) { slot in
                    DeckSlotTileView(
                        slot: slot,
                        isEditing: isEditing,
                        onSelect: {
                            ActionExecutionService.shared.execute(slot: slot)
                        },
                        onEdit: {
                            onEditSlot(slot)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: 520, height: 172)
    }
}
```

- [ ] **Step 3: Implement `NotchDeckRootView.swift`**

```swift
import SwiftUI

public struct NotchDeckRootView: View {
    @ObservedObject var configManager = ConfigManager.shared
    @Binding var isExpanded: Bool
    public let hasPhysicalNotch: Bool
    public let onOpenSettings: () -> Void
    public let onEditSlot: (DeckSlot) -> Void

    public var body: some View {
        ZStack(alignment: .top) {
            LiquidGlassBackground(
                cornerRadius: isExpanded ? 24 : (hasPhysicalNotch ? 12 : 16),
                specularIntensity: configManager.config.appearance.specularIntensity,
                isExpanded: isExpanded
            )

            if isExpanded {
                ExpandedDeckView(
                    configManager: configManager,
                    onCollapse: { withAnimation(.interactiveSpring(response: 0.36, dampingFraction: 0.74)) { isExpanded = false } },
                    onOpenSettings: onOpenSettings,
                    onEditSlot: onEditSlot
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.94, anchor: .top)),
                    removal: .opacity
                ))
            } else {
                CollapsedNotchView(
                    hasPhysicalNotch: hasPhysicalNotch,
                    onExpand: { withAnimation(.interactiveSpring(response: 0.36, dampingFraction: 0.74)) { isExpanded = true } }
                )
                .transition(.opacity)
            }
        }
        .frame(
            width: isExpanded ? 520 : 180,
            height: isExpanded ? 172 : 32
        )
    }
}
```

- [ ] **Step 4: Build to verify compilation**

Run: `cd macos/NotchDeck && swift build`
Expected: Build complete with 0 errors.

- [ ] **Step 5: Commit**

```bash
git add macos/NotchDeck/Sources/NotchDeck/Views/
git commit -m "feat(notchdeck): add collapsed and expanded notch interactive views"
```

---

### Task 6: Customization Interfaces (Inline Editor & Settings)

**Files:**
- Create: `macos/NotchDeck/Sources/NotchDeck/Views/InlineSlotEditorSheet.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/Views/Settings/SettingsView.swift`

**Interfaces:**
- Consumes: `DeckSlot`, `ActionType`, `AppScannerService`, `ConfigManager`
- Produces: `InlineSlotEditorSheet` and `SettingsView`

- [ ] **Step 1: Implement `InlineSlotEditorSheet.swift`**

```swift
import SwiftUI

public struct InlineSlotEditorSheet: View {
    @Binding var slot: DeckSlot
    public let onSave: (DeckSlot) -> Void
    public let onCancel: () -> Void

    @State private var selectedActionType: ActionType
    @State private var title: String
    @State private var target: String
    @State private var iconName: String
    @State private var searchText = ""
    @State private var availableApps: [InstalledAppInfo] = []

    public init(slot: Binding<DeckSlot>, onSave: @escaping (DeckSlot) -> Void, onCancel: @escaping () -> Void) {
        self._slot = slot
        self.onSave = onSave
        self.onCancel = onCancel
        self._selectedActionType = State(initialValue: slot.wrappedValue.actionType)
        self._title = State(initialValue: slot.wrappedValue.title)
        self._target = State(initialValue: slot.wrappedValue.target)
        self._iconName = State(initialValue: slot.wrappedValue.iconName ?? "square.fill")
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Edit Slot #\(slot.index + 1)")
                .font(.headline)
                .foregroundColor(.white)

            Picker("Action Type", selection: $selectedActionType) {
                Text("App").tag(ActionType.appLauncher)
                Text("Media").tag(ActionType.mediaControl)
                Text("System").tag(ActionType.systemToggle)
                Text("Script").tag(ActionType.shellScript)
                Text("URL").tag(ActionType.urlBookmark)
            }
            .pickerStyle(.segmented)

            // Dynamic Form based on ActionType
            VStack(alignment: .leading, spacing: 10) {
                TextField("Label", text: $title)
                    .textFieldStyle(.roundedBorder)

                if selectedActionType == .appLauncher {
                    TextField("Search installed apps...", text: $searchText)
                        .textFieldStyle(.roundedBorder)

                    List(filteredApps) { app in
                        HStack {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                            Text(app.name)
                            Spacer()
                            if target == app.bundleIdentifier {
                                Image(systemName: "checkmark").foregroundColor(.cyan)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            target = app.bundleIdentifier
                            if title.isEmpty || title == "New Slot" {
                                title = app.name
                            }
                        }
                    }
                    .frame(height: 120)
                } else if selectedActionType == .systemToggle {
                    Picker("System Action", selection: $target) {
                        Text("Microphone Mute").tag("micMute")
                        Text("Volume Mute").tag("volumeMute")
                        Text("Screenshot Tool").tag("screenshot")
                        Text("Lock Screen").tag("lockScreen")
                    }
                } else if selectedActionType == .mediaControl {
                    Picker("Media Command", selection: $target) {
                        Text("Play / Pause").tag("playPause")
                        Text("Next Track").tag("nextTrack")
                        Text("Previous Track").tag("previousTrack")
                    }
                } else if selectedActionType == .shellScript {
                    TextField("Shell Command (e.g. open -a Simulator)", text: $target)
                        .textFieldStyle(.roundedBorder)
                } else if selectedActionType == .urlBookmark {
                    TextField("URL (e.g. https://github.com)", text: $target)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button("Save") {
                    var updated = slot
                    updated.actionType = selectedActionType
                    updated.title = title
                    updated.target = target
                    updated.iconName = defaultIconFor(action: selectedActionType, target: target)
                    onSave(updated)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 360, height: 320)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .onAppear {
            self.availableApps = AppScannerService.shared.scanInstalledApps()
        }
    }

    private var filteredApps: [InstalledAppInfo] {
        if searchText.isEmpty { return availableApps }
        return availableApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func defaultIconFor(action: ActionType, target: String) -> String {
        switch action {
        case .appLauncher: return "app.fill"
        case .mediaControl: return "playpause.fill"
        case .systemToggle:
            if target == "micMute" { return "mic.fill" }
            if target == "volumeMute" { return "speaker.slash.fill" }
            if target == "screenshot" { return "camera.fill" }
            return "lock.fill"
        case .shellScript: return "terminal.fill"
        case .urlBookmark: return "link"
        }
    }
}
```

- [ ] **Step 2: Implement `SettingsView.swift`**

```swift
import SwiftUI

public struct SettingsView: View {
    @ObservedObject var configManager = ConfigManager.shared

    public var body: some View {
        TabView {
            // General Tab
            Form {
                Section("Deck Layout") {
                    Stepper("Columns: \(configManager.config.gridColumns)", value: Binding(
                        get: { configManager.config.gridColumns },
                        set: {
                            var updated = configManager.config
                            updated.gridColumns = $0
                            try? configManager.saveConfig(updated)
                        }
                    ), in: 4...6)
                }

                Section("Presets") {
                    Button("Reset to Default 10-Slot Deck") {
                        configManager.resetToDefault()
                    }
                    .foregroundColor(.red)
                }
            }
            .tabItem { Label("General", systemImage: "gearshape") }
            .padding()

            // Appearance Tab
            Form {
                Section("Liquid Glass Customization") {
                    Slider(
                        value: Binding(
                            get: { configManager.config.appearance.specularIntensity },
                            set: {
                                var updated = configManager.config
                                updated.appearance.specularIntensity = $0
                                try? configManager.saveConfig(updated)
                            }
                        ),
                        in: 0.1...1.0,
                        step: 0.05
                    ) {
                        Text("Specular Reflection Highlight Rim")
                    }

                    Toggle("Ambient Backlight Glow", isOn: Binding(
                        get: { configManager.config.appearance.ambientBacklightEnabled },
                        set: {
                            var updated = configManager.config
                            updated.appearance.ambientBacklightEnabled = $0
                            try? configManager.saveConfig(updated)
                        }
                    ))
                }
            }
            .tabItem { Label("Appearance", systemImage: "sparkles") }
            .padding()
        }
        .frame(width: 420, height: 260)
    }
}
```

- [ ] **Step 3: Build to verify compilation**

Run: `cd macos/NotchDeck && swift build`
Expected: Build complete with 0 errors.

- [ ] **Step 4: Commit**

```bash
git add macos/NotchDeck/Sources/NotchDeck/Views/
git commit -m "feat(notchdeck): add inline slot editor and settings views"
```

---

### Task 7: Window Architecture & Notch Lifecycle

**Files:**
- Create: `macos/NotchDeck/Sources/NotchDeck/App/NotchPanel.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/App/NotchWindowController.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/App/AppDelegate.swift`
- Create: `macos/NotchDeck/Sources/NotchDeck/App/NotchDeckApp.swift`
- Create: `scripts/run_notchdeck.sh`
- Test: `macos/NotchDeck/Tests/NotchDeckTests/ScreenGeometryTests.swift`

**Interfaces:**
- Consumes: All views, models, and services
- Produces: Standalone runnable macOS app, `NotchPanel`, `NotchWindowController` anchored to notch with click handling and click-outside dismissal

- [ ] **Step 1: Write unit tests for screen notch calculations (`ScreenGeometryTests.swift`)**

```swift
import XCTest
@testable import NotchDeck

final class ScreenGeometryTests: XCTestCase {
    func testPhysicalNotchDetectedWhenTopInsetLarge() {
        let geo = ScreenGeometry(screenWidth: 1512, screenHeight: 982, topSafeAreaInset: 32)
        XCTAssertTrue(geo.hasPhysicalNotch)
        XCTAssertEqual(geo.notchCollapsedSize.height, 32)
    }

    func testExternalDisplayTreatedAsSimulatedNotch() {
        let geo = ScreenGeometry(screenWidth: 2560, screenHeight: 1440, topSafeAreaInset: 0)
        XCTAssertFalse(geo.hasPhysicalNotch)
        XCTAssertEqual(geo.notchCollapsedSize.height, 34)
    }
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `cd macos/NotchDeck && swift test --filter ScreenGeometryTests`
Expected: PASS

- [ ] **Step 3: Implement `NotchPanel.swift`**

```swift
import AppKit

public final class NotchPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isFloatingPanel = true
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.isMovable = false
    }

    public override var canBecomeKey: Bool {
        return true
    }
}
```

- [ ] **Step 4: Implement `NotchWindowController.swift`**

```swift
import AppKit
import SwiftUI

public final class NotchWindowController: NSObject, ObservableObject {
    public static let shared = NotchWindowController()

    public private(set) var panel: NotchPanel?
    public private(set) var settingsWindow: NSWindow?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var isExpanded: Bool = false
    private var editingSlot: DeckSlot?

    public func start() {
        setupWindow()
        setupEventMonitors()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            nil
        )
    }

    private func setupWindow() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let geo = ScreenGeometry(
            screenWidth: screen.frame.width,
            screenHeight: screen.frame.height,
            topSafeAreaInset: screen.safeAreaInsets.top
        )

        let initialSize = geo.notchCollapsedSize
        let initialX = screen.frame.midX - initialSize.width / 2
        let initialY = screen.frame.maxY - initialSize.height

        let contentRect = NSRect(x: initialX, y: initialY, width: initialSize.width, height: initialSize.height)
        let panel = NotchPanel(contentRect: contentRect)

        let rootView = NotchDeckRootView(
            isExpanded: Binding(
                get: { self.isExpanded },
                set: { self.setExpanded($0) }
            ),
            hasPhysicalNotch: geo.hasPhysicalNotch,
            onOpenSettings: { [weak self] in self?.openSettings() },
            onEditSlot: { [weak self] slot in self?.openSlotEditor(slot) }
        )

        panel.contentView = NSHostingView(rootView: rootView)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    public func setExpanded(_ expanded: Bool) {
        guard self.isExpanded != expanded else { return }
        self.isExpanded = expanded

        guard let screen = NSScreen.main ?? NSScreen.screens.first,
              let panel = self.panel else { return }

        let targetSize = expanded ? CGSize(width: 520, height: 172) : CGSize(width: 180, height: max(32, screen.safeAreaInsets.top))
        let targetX = screen.frame.midX - targetSize.width / 2
        let targetY = screen.frame.maxY - targetSize.height

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(NSRect(x: targetX, y: targetY, width: targetSize.width, height: targetSize.height), display: true)
        }
    }

    private func setupEventMonitors() {
        // Outside click detector
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isExpanded else { return }
            let mouseLoc = NSEvent.mouseLocation
            if let frame = self.panel?.frame, !frame.contains(mouseLoc) {
                DispatchQueue.main.async {
                    self.setExpanded(false)
                }
            }
        }
    }

    public func openSettings() {
        if let existing = settingsWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "NotchDeck Preferences"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.settingsWindow = window
    }

    public func openSlotEditor(_ slot: DeckSlot) {
        let editorWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        editorWindow.title = "Edit Slot"
        editorWindow.center()

        var currentSlot = slot
        let sheet = InlineSlotEditorSheet(
            slot: Binding(get: { currentSlot }, set: { currentSlot = $0 }),
            onSave: { updated in
                ConfigManager.shared.updateSlot(updated)
                editorWindow.close()
            },
            onCancel: {
                editorWindow.close()
            }
        )
        editorWindow.contentView = NSHostingView(rootView: sheet)
        editorWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func screenParametersChanged() {
        guard let screen = NSScreen.main, let panel = self.panel else { return }
        let targetSize = isExpanded ? CGSize(width: 520, height: 172) : CGSize(width: 180, height: max(32, screen.safeAreaInsets.top))
        panel.setFrame(NSRect(x: screen.frame.midX - targetSize.width / 2, y: screen.frame.maxY - targetSize.height, width: targetSize.width, height: targetSize.height), display: true)
    }
}
```

- [ ] **Step 5: Implement `AppDelegate.swift` and `NotchDeckApp.swift`**

`AppDelegate.swift`:
```swift
import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NotchWindowController.shared.start()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.topthird.inset.filled", accessibilityDescription: "NotchDeck")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Notch Deck", action: #selector(toggleDeck), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit NotchDeck", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc private func toggleDeck() {
        let isExpanded = NotchWindowController.shared.panel?.frame.height ?? 0 > 50
        NotchWindowController.shared.setExpanded(!isExpanded)
    }

    @objc private func openPreferences() {
        NotchWindowController.shared.openSettings()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
```

`NotchDeckApp.swift`:
```swift
import AppKit

@main
enum NotchDeckMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
```

- [ ] **Step 6: Create helper script `scripts/run_notchdeck.sh`**

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Building NotchDeck (macOS Native Liquid Glass Notch Stream Deck)..."
cd "$ROOT_DIR/macos/NotchDeck"
swift build -c release

echo "==> Launching NotchDeck..."
"$ROOT_DIR/macos/NotchDeck/.build/release/NotchDeck"
```

Make it executable: `chmod +x scripts/run_notchdeck.sh`

- [ ] **Step 7: Build and run all unit tests**

Run: `cd macos/NotchDeck && swift test`
Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add macos/NotchDeck/ scripts/run_notchdeck.sh
git commit -m "feat(notchdeck): implement NotchPanel window architecture, AppDelegate, and runner script"
```

---

### Task 8: Verification & End-to-End Build

**Files:**
- Test all components end-to-end
- Run static analysis / compiler checks
- Verify persistence and clean launch

- [ ] **Step 1: Execute full test suite**

Run: `cd macos/NotchDeck && swift test`
Expected: 100% passing tests.

- [ ] **Step 2: Build release binary**

Run: `cd macos/NotchDeck && swift build -c release`
Expected: Successful build of `NotchDeck` binary.

- [ ] **Step 3: Commit and update documentation**

```bash
git add .
git commit -m "chore(notchdeck): complete full build and verification"
```
