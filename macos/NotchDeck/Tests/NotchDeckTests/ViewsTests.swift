import XCTest
import SwiftUI
import AppKit
@testable import NotchDeck

final class ViewsTests: XCTestCase {

    func testVisualEffectViewHostingAndProperties() {
        let visualEffectView = VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        XCTAssertEqual(visualEffectView.material, .hudWindow)
        XCTAssertEqual(visualEffectView.blendingMode, .behindWindow)

        let hostingView = NSHostingView(rootView: visualEffectView)
        hostingView.layout()
        XCTAssertNotNil(hostingView)
    }

    func testLiquidGlassBackgroundDefaultAndCustomInits() {
        let defaultBg = LiquidGlassBackground()
        XCTAssertEqual(defaultBg.cornerRadius, 24.0)
        XCTAssertEqual(defaultBg.specularIntensity, 0.45)
        XCTAssertTrue(defaultBg.isExpanded)
        XCTAssertNotNil(defaultBg.body)

        let customBg = LiquidGlassBackground(cornerRadius: 18.0, specularIntensity: 0.75, isExpanded: false)
        XCTAssertEqual(customBg.cornerRadius, 18.0)
        XCTAssertEqual(customBg.specularIntensity, 0.75)
        XCTAssertFalse(customBg.isExpanded)
        XCTAssertNotNil(customBg.body)

        let settings = GlassAppearanceSettings(
            blurMaterial: "hud",
            specularIntensity: 0.6,
            ambientBacklightEnabled: true,
            cornerRadius: 28.0
        )
        let settingsBg = LiquidGlassBackground(settings: settings, isExpanded: true)
        XCTAssertEqual(settingsBg.cornerRadius, 28.0)
        XCTAssertEqual(settingsBg.specularIntensity, 0.6)
        XCTAssertTrue(settingsBg.isExpanded)
        XCTAssertNotNil(settingsBg.body)

        let hostingView = NSHostingView(rootView: settingsBg)
        hostingView.layout()
        XCTAssertNotNil(hostingView)
    }

    func testDeckSlotTileViewSelectionAndEditCallbacks() {
        let slot = DeckSlot(
            index: 0,
            title: "Terminal",
            actionType: .appLauncher,
            target: "com.apple.Terminal",
            iconName: "terminal"
        )

        var selected = false
        var edited = false

        let normalTile = DeckSlotTileView(
            slot: slot,
            isEditing: false,
            onSelect: { selected = true },
            onEdit: { edited = true }
        )

        XCTAssertEqual(normalTile.slot.title, "Terminal")
        XCTAssertFalse(normalTile.isEditing)
        XCTAssertNotNil(normalTile.body)

        normalTile.onSelect()
        XCTAssertTrue(selected)
        XCTAssertFalse(edited)

        let editTile = DeckSlotTileView(
            slot: slot,
            isEditing: true,
            onSelect: { selected = true },
            onEdit: { edited = true }
        )

        XCTAssertTrue(editTile.isEditing)
        XCTAssertNotNil(editTile.body)

        editTile.onEdit()
        XCTAssertTrue(edited)

        let hostingView = NSHostingView(rootView: normalTile)
        hostingView.layout()
        XCTAssertNotNil(hostingView)
    }

    func testDeckSlotTileViewDifferentActionTypes() {
        let mediaSlot = DeckSlot(
            index: 1,
            title: "Play/Pause",
            actionType: .mediaControl,
            target: "playPause",
            iconName: "playpause.fill"
        )
        let mediaTile = DeckSlotTileView(slot: mediaSlot, onSelect: {}, onEdit: {})
        XCTAssertNotNil(mediaTile.body)

        let micSlot = DeckSlot(
            index: 2,
            title: "Mic Mute",
            actionType: .systemToggle,
            target: "micMute",
            iconName: "mic.slash"
        )
        let micTile = DeckSlotTileView(slot: micSlot, onSelect: {}, onEdit: {})
        XCTAssertNotNil(micTile.body)

        let fallbackSlot = DeckSlot(
            index: 3,
            title: "Generic",
            actionType: .shellScript,
            target: "echo hello",
            iconName: nil
        )
        let fallbackTile = DeckSlotTileView(slot: fallbackSlot, onSelect: {}, onEdit: {})
        XCTAssertNotNil(fallbackTile.body)

        let bookmarkSlot = DeckSlot(
            index: 4,
            title: "Docs",
            actionType: .urlBookmark,
            target: "https://apple.com",
            iconName: "safari"
        )
        let bookmarkTile = DeckSlotTileView(slot: bookmarkSlot, onSelect: {}, onEdit: {})
        XCTAssertNotNil(bookmarkTile.body)

        let hostingView = NSHostingView(rootView: bookmarkTile)
        hostingView.layout()
        XCTAssertNotNil(hostingView)
    }

    func testCollapsedNotchViewPropertiesAndCallbacks() {
        var expanded = false
        let collapsedView = CollapsedNotchView(hasPhysicalNotch: true, onExpand: {
            expanded = true
        })

        XCTAssertTrue(collapsedView.hasPhysicalNotch)
        XCTAssertNotNil(collapsedView.body)

        collapsedView.onExpand()
        XCTAssertTrue(expanded)

        let noNotchView = CollapsedNotchView(hasPhysicalNotch: false, onExpand: {})
        XCTAssertFalse(noNotchView.hasPhysicalNotch)
        XCTAssertNotNil(noNotchView.body)

        let hostingView = NSHostingView(rootView: collapsedView)
        hostingView.layout()
        XCTAssertNotNil(hostingView)
    }

    func testExpandedDeckViewPropertiesAndCallbacks() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("config.json")
        let configManager = ConfigManager(fileURL: fileURL)

        var collapsed = false
        var settingsOpened = false
        var editedSlot: DeckSlot? = nil

        let expandedView = ExpandedDeckView(
            configManager: configManager,
            onCollapse: { collapsed = true },
            onOpenSettings: { settingsOpened = true },
            onEditSlot: { slot in editedSlot = slot }
        )

        XCTAssertNotNil(expandedView.body)

        expandedView.onCollapse()
        XCTAssertTrue(collapsed)

        expandedView.onOpenSettings()
        XCTAssertTrue(settingsOpened)

        let testSlot = configManager.config.slots.first!
        expandedView.onEditSlot(testSlot)
        XCTAssertEqual(editedSlot?.id, testSlot.id)

        let editingView = ExpandedDeckView(
            configManager: configManager,
            isEditing: true,
            onCollapse: {},
            onOpenSettings: {},
            onEditSlot: { _ in }
        )
        XCTAssertNotNil(editingView.body)

        let hostingView = NSHostingView(rootView: expandedView)
        hostingView.layout()
        XCTAssertNotNil(hostingView)
    }

    func testNotchDeckRootViewExpansionStateAndHosting() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("config.json")
        let configManager = ConfigManager(fileURL: fileURL)

        var isExpandedState = false
        var settingsOpened = false
        var editedSlot: DeckSlot? = nil

        let isExpandedBinding = Binding<Bool>(
            get: { isExpandedState },
            set: { isExpandedState = $0 }
        )

        let collapsedRoot = NotchDeckRootView(
            configManager: configManager,
            isExpanded: isExpandedBinding,
            hasPhysicalNotch: false,
            onOpenSettings: { settingsOpened = true },
            onEditSlot: { slot in editedSlot = slot }
        )

        XCTAssertFalse(collapsedRoot.hasPhysicalNotch)
        XCTAssertNotNil(collapsedRoot.body)

        let hostingCollapsed = NSHostingView(rootView: collapsedRoot)
        hostingCollapsed.layout()
        XCTAssertNotNil(hostingCollapsed)

        // Switch to expanded
        isExpandedState = true

        let expandedRoot = NotchDeckRootView(
            configManager: configManager,
            isExpanded: isExpandedBinding,
            hasPhysicalNotch: true,
            onOpenSettings: { settingsOpened = true },
            onEditSlot: { slot in editedSlot = slot }
        )

        XCTAssertTrue(expandedRoot.hasPhysicalNotch)
        XCTAssertNotNil(expandedRoot.body)

        let hostingExpanded = NSHostingView(rootView: expandedRoot)
        hostingExpanded.layout()
        XCTAssertNotNil(hostingExpanded)

        // Verify callbacks passed down
        expandedRoot.onOpenSettings()
        XCTAssertTrue(settingsOpened)

        let targetSlot = configManager.config.slots[0]
        expandedRoot.onEditSlot(targetSlot)
        XCTAssertEqual(editedSlot?.id, targetSlot.id)
    }

    func testInlineSlotEditorSheetDefaultIconMapping() {
        XCTAssertEqual(InlineSlotEditorSheet.defaultIconFor(action: .appLauncher, target: "com.apple.finder"), "app.fill")
        XCTAssertEqual(InlineSlotEditorSheet.defaultIconFor(action: .mediaControl, target: "playPause"), "playpause.fill")
        XCTAssertEqual(InlineSlotEditorSheet.defaultIconFor(action: .systemToggle, target: "micMute"), "mic.fill")
        XCTAssertEqual(InlineSlotEditorSheet.defaultIconFor(action: .systemToggle, target: "volumeMute"), "speaker.slash.fill")
        XCTAssertEqual(InlineSlotEditorSheet.defaultIconFor(action: .systemToggle, target: "screenshot"), "camera.fill")
        XCTAssertEqual(InlineSlotEditorSheet.defaultIconFor(action: .systemToggle, target: "lockScreen"), "lock.fill")
        XCTAssertEqual(InlineSlotEditorSheet.defaultIconFor(action: .systemToggle, target: "unknownAction"), "lock.fill")
        XCTAssertEqual(InlineSlotEditorSheet.defaultIconFor(action: .shellScript, target: "echo hi"), "terminal.fill")
        XCTAssertEqual(InlineSlotEditorSheet.defaultIconFor(action: .urlBookmark, target: "https://apple.com"), "link")
    }

    func testInlineSlotEditorSheetBuildUpdatedSlot() {
        let original = DeckSlot(
            index: 2,
            title: "Original",
            actionType: .appLauncher,
            target: "com.apple.finder",
            iconName: "folder"
        )

        let updated = InlineSlotEditorSheet.buildUpdatedSlot(
            from: original,
            actionType: .systemToggle,
            title: "Mute Mic",
            target: "micMute"
        )

        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.index, 2)
        XCTAssertEqual(updated.actionType, .systemToggle)
        XCTAssertEqual(updated.title, "Mute Mic")
        XCTAssertEqual(updated.target, "micMute")
        XCTAssertEqual(updated.iconName, "mic.fill")
    }

    func testInlineSlotEditorSheetFilterApps() {
        let apps = [
            InstalledAppInfo(name: "Safari", bundleIdentifier: "com.apple.Safari", path: "/Applications/Safari.app"),
            InstalledAppInfo(name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", path: "/Applications/Xcode.app"),
            InstalledAppInfo(name: "Terminal", bundleIdentifier: "com.apple.Terminal", path: "/Applications/Utilities/Terminal.app")
        ]

        let emptySearch = InlineSlotEditorSheet.filterApps(apps, searchText: "")
        XCTAssertEqual(emptySearch.count, 3)

        let filteredSafari = InlineSlotEditorSheet.filterApps(apps, searchText: "saf")
        XCTAssertEqual(filteredSafari.count, 1)
        XCTAssertEqual(filteredSafari.first?.name, "Safari")

        let filteredNone = InlineSlotEditorSheet.filterApps(apps, searchText: "nonexistentapp")
        XCTAssertTrue(filteredNone.isEmpty)
    }

    func testInlineSlotEditorSheetViewCallbacksAndHosting() {
        var testSlot = DeckSlot(
            index: 0,
            title: "Old Slot",
            actionType: .appLauncher,
            target: "com.apple.finder",
            iconName: "app.fill"
        )
        let slotBinding = Binding<DeckSlot>(
            get: { testSlot },
            set: { testSlot = $0 }
        )

        var cancelled = false
        var savedSlot: DeckSlot? = nil

        let sheet = InlineSlotEditorSheet(
            slot: slotBinding,
            initialApps: [
                InstalledAppInfo(name: "Calculator", bundleIdentifier: "com.apple.calculator", path: "/Applications/Calculator.app")
            ],
            onSave: { updated in savedSlot = updated },
            onCancel: { cancelled = true }
        )

        let hostingView = NSHostingView(rootView: sheet)
        hostingView.layout()
        XCTAssertNotNil(hostingView)

        sheet.onCancel()
        XCTAssertTrue(cancelled)

        let newSlot = DeckSlot(
            index: 0,
            title: "New Label",
            actionType: .urlBookmark,
            target: "https://apple.com",
            iconName: "link"
        )
        sheet.onSave(newSlot)
        XCTAssertEqual(savedSlot?.title, "New Label")
        XCTAssertEqual(savedSlot?.target, "https://apple.com")
    }

    func testSettingsViewInitializationAndHosting() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("config.json")
        let configManager = ConfigManager(fileURL: fileURL)

        let settingsView = SettingsView(configManager: configManager)
        XCTAssertNotNil(settingsView.body)

        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.layout()
        XCTAssertNotNil(hostingView)
    }

    func testSettingsViewConfigUpdatesAndReset() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("config.json")
        let configManager = ConfigManager(fileURL: fileURL)

        XCTAssertEqual(configManager.config.gridColumns, 5)

        // Modify columns
        var config = configManager.config
        config.gridColumns = 6
        config.appearance.specularIntensity = 0.8
        config.appearance.ambientBacklightEnabled = false
        try? configManager.saveConfig(config)

        XCTAssertEqual(configManager.config.gridColumns, 6)
        XCTAssertEqual(configManager.config.appearance.specularIntensity, 0.8)
        XCTAssertFalse(configManager.config.appearance.ambientBacklightEnabled)

        // Reset to default
        configManager.resetToDefault()
        XCTAssertEqual(configManager.config.gridColumns, 5)
        XCTAssertEqual(configManager.config.slots.count, 10)
        XCTAssertTrue(configManager.config.appearance.ambientBacklightEnabled)
    }

    func testPhoneDeckServiceInitializationAndDefaults() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = PhoneDeckService(baseDirectory: tempDir)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertEqual(service.slots.count, 6)
        XCTAssertEqual(service.slots[0].label, "VS Code")
        XCTAssertEqual(service.slots[0].bundleId, "com.microsoft.VSCode")
        XCTAssertFalse(service.slots[0].isEmpty)

        let profileFile = tempDir.appendingPathComponent("profile.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: profileFile.path))
    }

    func testPhoneDeckServiceSetAndClearSlot() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = PhoneDeckService(baseDirectory: tempDir)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        // Assign a new app to slot 1
        let calcApp = InstalledAppInfo(name: "Calculator", bundleIdentifier: "com.apple.calculator", path: "/System/Applications/Calculator.app", icon: nil)
        service.setSlotApp(index: 1, app: calcApp)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertEqual(service.slots[1].label, "Calculator")
        XCTAssertEqual(service.slots[1].bundleId, "com.apple.calculator")
        XCTAssertFalse(service.slots[1].isEmpty)

        // Clear slot 1 via minus badge logic
        service.clearSlot(index: 1)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertTrue(service.slots[1].isEmpty)
        XCTAssertEqual(service.slots[1].label, "")
        XCTAssertEqual(service.slots[1].bundleId, "")

        // Reset defaults
        service.resetDefaults()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertEqual(service.slots[1].label, "Terminal")
        XCTAssertEqual(service.slots[1].bundleId, "com.apple.Terminal")
    }

    func testPhoneDeckServiceLoadStatusFile() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = PhoneDeckService(baseDirectory: tempDir)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertFalse(service.isDeviceConnected)

        // Write a connected status.json
        let statusFile = tempDir.appendingPathComponent("status.json")
        let status = DeviceStatusInfo(connected: true, clientName: "Pixel 8 Pro", clientCount: 1)
        let data = try? JSONEncoder().encode(status)
        try? data?.write(to: statusFile)

        service.loadStatus()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertTrue(service.isDeviceConnected)
        XCTAssertEqual(service.connectedDeviceName, "Pixel 8 Pro")
        XCTAssertEqual(service.clientCount, 1)
    }

    func testDeckSlotCardViewConfiguredAndEmptyState() {
        let configuredSlot = PhoneDeckSlot(id: "app-1", index: 0, label: "VS Code", bundleId: "com.microsoft.VSCode")
        var edited = false
        var removed = false

        let configuredCard = DeckSlotCardView(
            slot: configuredSlot,
            onEdit: { edited = true },
            onRemove: { removed = true }
        )
        XCTAssertFalse(configuredSlot.isEmpty)
        XCTAssertNotNil(configuredCard.body)

        configuredCard.onEdit()
        XCTAssertTrue(edited)

        configuredCard.onRemove()
        XCTAssertTrue(removed)

        let hosting1 = NSHostingView(rootView: configuredCard)
        hosting1.layout()
        XCTAssertNotNil(hosting1)

        // Empty state card
        let emptySlot = PhoneDeckSlot(id: "app-2", index: 1, label: "", bundleId: "")
        XCTAssertTrue(emptySlot.isEmpty)

        var emptyTapped = false
        let emptyCard = DeckSlotCardView(
            slot: emptySlot,
            onEdit: { emptyTapped = true },
            onRemove: {}
        )
        XCTAssertNotNil(emptyCard.body)

        emptyCard.onEdit()
        XCTAssertTrue(emptyTapped)

        let hosting2 = NSHostingView(rootView: emptyCard)
        hosting2.layout()
        XCTAssertNotNil(hosting2)
    }

    func testPhoneAppPickerSheetSelectionAndCancel() {
        let mockApp = InstalledAppInfo(name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", path: "/Applications/Xcode.app", icon: nil)
        var selectedApp: InstalledAppInfo? = nil
        var cancelled = false

        let sheet = PhoneAppPickerSheet(
            slotIndex: 0,
            currentBundleId: "",
            initialApps: [mockApp],
            onSelectApp: { app in selectedApp = app },
            onCancel: { cancelled = true }
        )
        XCTAssertNotNil(sheet.body)

        sheet.onSelectApp(mockApp)
        XCTAssertEqual(selectedApp?.name, "Xcode")
        XCTAssertEqual(selectedApp?.bundleIdentifier, "com.apple.dt.Xcode")

        sheet.onCancel()
        XCTAssertTrue(cancelled)

        let hosting = NSHostingView(rootView: sheet)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }

    func testExpandedDeckViewRendering() {
        let appsView = ExpandedDeckView(
            onCollapse: {},
            onOpenSettings: {},
            onSelectSlotToEdit: { _ in }
        )
        XCTAssertNotNil(appsView.body)

        let hosting = NSHostingView(rootView: appsView)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }
}



