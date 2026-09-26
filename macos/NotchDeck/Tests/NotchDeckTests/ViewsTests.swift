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
        let status = DeviceStatusInfo(connected: true, clientName: "Pixel 8 Pro", clientCount: 1, batteryLevel: 88, isCharging: true)
        let data = try? JSONEncoder().encode(status)
        try? data?.write(to: statusFile)

        service.loadStatus()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertTrue(service.isDeviceConnected)
        XCTAssertEqual(service.connectedDeviceName, "Pixel 8 Pro")
        XCTAssertEqual(service.clientCount, 1)
        XCTAssertEqual(service.batteryLevel, 88)
        XCTAssertTrue(service.isCharging)
    }

    func testCollapsedNotchViewBatteryRendering() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let statusFile = tempDir.appendingPathComponent("status.json")
        let status = DeviceStatusInfo(connected: true, clientName: "Pixel 8 Pro", clientCount: 1, batteryLevel: 72, isCharging: false)
        let data = try JSONEncoder().encode(status)
        try data.write(to: statusFile, options: .atomic)

        let service = PhoneDeckService(baseDirectory: tempDir)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        let view = CollapsedNotchView(phoneDeckService: service, onExpand: {})
        let hosting = NSHostingView(rootView: view)
        XCTAssertNotNil(hosting)
        XCTAssertTrue(service.isDeviceConnected)
        XCTAssertEqual(service.batteryLevel, 72)
        XCTAssertFalse(service.isCharging)
    }

    func testCollapsedNotchViewConnectedWithoutBatteryShowsReadyNotOffline() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = PhoneDeckService(baseDirectory: tempDir)
        service.setDeviceConnected(true, name: "Pixel 8", count: 1)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertTrue(service.isDeviceConnected)
        XCTAssertNil(service.batteryLevel)

        let view = CollapsedNotchView(phoneDeckService: service, onExpand: {})
        let hosting = NSHostingView(rootView: view)
        XCTAssertNotNil(hosting)
    }

    func testPhoneDeckServiceBatteryPersistenceAndStatusSave() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = PhoneDeckService(baseDirectory: tempDir)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        service.setDeviceConnected(true, name: "Galaxy S24", count: 1)
        service.updateBattery(level: 85, charging: true)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertEqual(service.batteryLevel, 85)
        XCTAssertTrue(service.isCharging)

        // Verify status.json was saved with the battery info
        let statusFile = tempDir.appendingPathComponent("status.json")
        let data = try Data(contentsOf: statusFile)
        let decoded = try JSONDecoder().decode(DeviceStatusInfo.self, from: data)
        XCTAssertTrue(decoded.connected)
        XCTAssertEqual(decoded.clientName, "Galaxy S24")
        XCTAssertEqual(decoded.batteryLevel, 85)
        XCTAssertEqual(decoded.isCharging, true)
    }

    func testPhoneDeckServiceLoadStatusPreservesExistingBatteryWhenOmitted() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = PhoneDeckService(baseDirectory: tempDir)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        service.setDeviceConnected(true, name: "V2427", count: 1)
        service.updateBattery(level: 79, charging: false)

        // Write a status.json without batteryLevel (e.g. from an older producer)
        let statusFile = tempDir.appendingPathComponent("status.json")
        let minimalStatus = DeviceStatusInfo(connected: true, clientName: "V2427", clientCount: 1, batteryLevel: nil, isCharging: nil)
        let data = try JSONEncoder().encode(minimalStatus)
        try data.write(to: statusFile, options: .atomic)

        service.loadStatus()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        // Battery level 79 should be preserved, not wiped to nil
        XCTAssertTrue(service.isDeviceConnected)
        XCTAssertEqual(service.batteryLevel, 79)
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

    func testSideNotchShapePathGeneration() {
        let rightShape = SideNotchShape(edge: .right, cornerRadius: 18, curlRadius: 16)
        let rightPath = rightShape.path(in: CGRect(x: 0, y: 0, width: 48, height: 180))
        XCTAssertFalse(rightPath.isEmpty)

        let leftShape = SideNotchShape(edge: .left, cornerRadius: 18, curlRadius: 16)
        let leftPath = leftShape.path(in: CGRect(x: 0, y: 0, width: 48, height: 180))
        XCTAssertFalse(leftPath.isEmpty)

        let topShape = SideNotchShape(edge: .top, cornerRadius: 18, curlRadius: 16)
        let topPath = topShape.path(in: CGRect(x: 0, y: 0, width: 180, height: 32))
        XCTAssertFalse(topPath.isEmpty)

        // Test insetting
        let inset = rightShape.inset(by: 2)
        XCTAssertEqual(inset.insetAmount, 2)
    }

    func testCollapsedNotchViewVerticalMode() {
        let view = CollapsedNotchView(edge: .right, onExpand: {})
        XCTAssertNotNil(view.body)

        let hosting = NSHostingView(rootView: view)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }

    func testExpandedDeckViewVerticalMode() {
        let view = ExpandedDeckView(
            edge: .right,
            onCollapse: {},
            onOpenSettings: {},
            onSelectSlotToEdit: { _ in }
        )
        XCTAssertNotNil(view.body)

        let hosting = NSHostingView(rootView: view)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }

    func testLiquidPullShapePathGeneration() {
        // Resting top shape
        let topResting = LiquidPullShape(edge: .top, stretchDistance: 0)
        let topRestingPath = topResting.path(in: CGRect(x: 0, y: 0, width: 180, height: 32))
        XCTAssertFalse(topRestingPath.isEmpty)

        // Stretched top shape with lateral offset
        let topStretched = LiquidPullShape(edge: .top, stretchDistance: 40, lateralOffset: 8)
        let topStretchedPath = topStretched.path(in: CGRect(x: 0, y: 0, width: 180, height: 72))
        XCTAssertFalse(topStretchedPath.isEmpty)

        // Stretched right shape
        let rightStretched = LiquidPullShape(edge: .right, stretchDistance: 35, lateralOffset: -4)
        let rightStretchedPath = rightStretched.path(in: CGRect(x: 0, y: 0, width: 83, height: 116))
        XCTAssertFalse(rightStretchedPath.isEmpty)

        // Stretched left shape
        let leftStretched = LiquidPullShape(edge: .left, stretchDistance: 35, lateralOffset: 4)
        let leftStretchedPath = leftStretched.path(in: CGRect(x: 0, y: 0, width: 83, height: 116))
        XCTAssertFalse(leftStretchedPath.isEmpty)

        // Detached droplet shape
        let detached = LiquidPullShape(edge: .top, stretchDistance: 0, isDetached: true)
        let detachedPath = detached.path(in: CGRect(x: 0, y: 0, width: 72, height: 40))
        XCTAssertFalse(detachedPath.isEmpty)

        // Insettable
        let inset = topStretched.inset(by: 3)
        XCTAssertEqual(inset.insetAmount, 3)
    }

    func testLiquidDropletContentView() {
        let horizontalDroplet = LiquidDropletContentView(edge: .top, isDetached: false)
        XCTAssertNotNil(horizontalDroplet.body)
        let hHosting = NSHostingView(rootView: horizontalDroplet)
        hHosting.layout()
        XCTAssertNotNil(hHosting)

        let verticalDroplet = LiquidDropletContentView(edge: .right, isDetached: false)
        XCTAssertNotNil(verticalDroplet.body)
        let vHosting = NSHostingView(rootView: verticalDroplet)
        vHosting.layout()
        XCTAssertNotNil(vHosting)

        let floatingDroplet = LiquidDropletContentView(edge: .top, isDetached: true)
        XCTAssertNotNil(floatingDroplet.body)
        let fHosting = NSHostingView(rootView: floatingDroplet)
        fHosting.layout()
        XCTAssertNotNil(fHosting)
    }

    func testNotchDeckRootViewStretchedAndDetachedMode() {
        var isExpanded = false
        let expandedBinding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        // Stretched top notch
        let stretchedView = NotchDeckRootView(
            isExpanded: expandedBinding,
            edge: .top,
            stretchDistance: 30.0,
            lateralOffset: 5.0,
            isDetached: false
        )
        XCTAssertNotNil(stretchedView.body)
        let sHosting = NSHostingView(rootView: stretchedView)
        sHosting.layout()
        XCTAssertNotNil(sHosting)

        // Detached floating droplet
        let detachedView = NotchDeckRootView(
            isExpanded: expandedBinding,
            edge: .right,
            stretchDistance: 0.0,
            lateralOffset: 0.0,
            isDetached: true
        )
        XCTAssertNotNil(detachedView.body)
        let dHosting = NSHostingView(rootView: detachedView)
        dHosting.layout()
        XCTAssertNotNil(dHosting)
    }

    func testDeckPresetModelAndDefaults() throws {
        let defaults = DeckPreset.defaultPresets()
        XCTAssertEqual(defaults.count, 3)
        XCTAssertEqual(defaults[0].name, "Development")
        XCTAssertEqual(defaults[1].name, "Productivity")
        XCTAssertEqual(defaults[2].name, "Media & Tools")

        // Each preset must strictly contain exactly 6 slots
        for preset in defaults {
            XCTAssertEqual(preset.slots.count, 6)
            for (idx, slot) in preset.slots.enumerated() {
                XCTAssertEqual(slot.index, idx)
                XCTAssertFalse(slot.label.isEmpty)
                XCTAssertFalse(slot.bundleId.isEmpty)
            }
        }

        // Test custom preset encoding and decoding
        let customSlots = [
            PhoneDeckSlot(id: "app-1", index: 0, label: "Figma", bundleId: "com.figma.Desktop"),
            PhoneDeckSlot(id: "app-2", index: 1, label: "Slack", bundleId: "com.tinyspeck.slackmacgap"),
            PhoneDeckSlot(id: "app-3", index: 2, label: "Notion", bundleId: "notion.id"),
            PhoneDeckSlot(id: "app-4", index: 3, label: "Spotify", bundleId: "com.spotify.client"),
            PhoneDeckSlot(id: "app-5", index: 4, label: "Linear", bundleId: "com.linear"),
            PhoneDeckSlot(id: "app-6", index: 5, label: "Safari", bundleId: "com.apple.Safari")
        ]
        let customPreset = DeckPreset(name: "Design Rig", slots: customSlots)
        let data = try JSONEncoder().encode(customPreset)
        let decoded = try JSONDecoder().decode(DeckPreset.self, from: data)
        XCTAssertEqual(decoded.id, customPreset.id)
        XCTAssertEqual(decoded.name, "Design Rig")
        XCTAssertEqual(decoded.slots.count, 6)
        XCTAssertEqual(decoded.slots[0].label, "Figma")
    }

    func testPhoneDeckServicePresetsLifecycle() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = PhoneDeckService(baseDirectory: tempDir)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        // Initialized with 3 default presets
        XCTAssertEqual(service.presets.count, 3)
        XCTAssertNotNil(service.activePresetId)
        XCTAssertEqual(service.activePresetId, service.presets.first?.id)

        let presetsFile = tempDir.appendingPathComponent("presets.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: presetsFile.path))

        // Save current deck as a new preset
        service.saveCurrentAsPreset(name: "Custom Workflow")
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertEqual(service.presets.count, 4)
        guard let savedPreset = service.presets.first(where: { $0.name == "Custom Workflow" }) else {
            XCTFail("Custom Workflow preset not found")
            return
        }
        XCTAssertEqual(service.activePresetId, savedPreset.id)
        XCTAssertEqual(savedPreset.slots.count, 6)

        // Rename preset
        service.renamePreset(id: savedPreset.id, newName: "Pro Workflow")
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        XCTAssertEqual(service.presets.first(where: { $0.id == savedPreset.id })?.name, "Pro Workflow")

        // Apply a different preset (e.g. Productivity)
        let prodPreset = service.presets[1]
        service.applyPreset(id: prodPreset.id)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertEqual(service.activePresetId, prodPreset.id)
        XCTAssertEqual(service.slots[0].label, prodPreset.slots[0].label)
        XCTAssertEqual(service.slots[0].bundleId, prodPreset.slots[0].bundleId)

        // Delete the custom preset
        service.deletePreset(id: savedPreset.id)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        XCTAssertEqual(service.presets.count, 3)
        XCTAssertNil(service.presets.first(where: { $0.id == savedPreset.id }))
    }

    func testGlassAppearanceSettingsTintOpacityAndBacklight() throws {
        // Defaults
        let defaultSettings = GlassAppearanceSettings()
        XCTAssertEqual(defaultSettings.glassTintOpacity, 0.72)
        XCTAssertTrue(defaultSettings.ambientBacklightEnabled)
        XCTAssertEqual(defaultSettings.specularIntensity, 0.45)

        // Custom init
        let customSettings = GlassAppearanceSettings(
            blurMaterial: "ultraThin",
            specularIntensity: 0.85,
            ambientBacklightEnabled: false,
            cornerRadius: 22.0,
            glassTintOpacity: 0.45
        )
        XCTAssertEqual(customSettings.glassTintOpacity, 0.45)
        XCTAssertFalse(customSettings.ambientBacklightEnabled)

        // JSON decode fallback when glassTintOpacity is omitted (backward compatibility)
        let jsonWithoutTint = """
        {
            "blurMaterial": "hud",
            "specularIntensity": 0.5,
            "ambientBacklightEnabled": true,
            "cornerRadius": 20.0
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(GlassAppearanceSettings.self, from: jsonWithoutTint)
        XCTAssertEqual(decoded.glassTintOpacity, 0.72)

        // LiquidGlassBackground with custom settings
        let bg = LiquidGlassBackground(settings: customSettings, edge: .top, isExpanded: true)
        XCTAssertEqual(bg.glassTintOpacity, 0.45)
        XCTAssertFalse(bg.ambientBacklightEnabled)
        XCTAssertEqual(bg.specularIntensity, 0.85)
        XCTAssertNotNil(bg.body)

        let hosting = NSHostingView(rootView: bg)
        hosting.layout()
        XCTAssertNotNil(hosting)
    }

    @MainActor
    func testSideNotchBubbleViewAndChatBubbleShape() {
        let rightShape = ChatBubbleShape(edge: .right, cornerRadius: 10, tailWidth: 5, tailHeight: 8)
        let rightPath = rightShape.path(in: CGRect(x: 0, y: 0, width: 160, height: 32))
        XCTAssertFalse(rightPath.isEmpty)

        let leftShape = ChatBubbleShape(edge: .left, cornerRadius: 10, tailWidth: 5, tailHeight: 8)
        let leftPath = leftShape.path(in: CGRect(x: 0, y: 0, width: 160, height: 32))
        XCTAssertFalse(leftPath.isEmpty)

        let topShape = ChatBubbleShape(edge: .top, cornerRadius: 10)
        let topPath = topShape.path(in: CGRect(x: 0, y: 0, width: 160, height: 32))
        XCTAssertFalse(topPath.isEmpty)

        let rightBubbleView = SideNotchBubbleView(edge: .right)
        XCTAssertNotNil(rightBubbleView.body)

        let leftBubbleView = SideNotchBubbleView(edge: .left)
        XCTAssertNotNil(leftBubbleView.body)

        let hosting = NSHostingView(rootView: rightBubbleView)
        hosting.layout()
        XCTAssertNotNil(hosting)

        // Test controller hover integration
        let controller = NotchWindowController.shared
        controller.start()
        controller.moveTo(edge: .right, positionRatio: 0.5, animated: false)
        controller.setSideNotchHovered(true)
        controller.setSideNotchHovered(false)
        controller.moveTo(edge: .top, positionRatio: 0.5, animated: false)
    }

    func testAppIconManagerResolutionAndCaching() {
        let manager = AppIconManager.shared

        // Test finding system Terminal by bundle ID
        let terminalURL = manager.findApplicationURL(bundleId: "com.apple.Terminal", name: "Terminal")
        XCTAssertNotNil(terminalURL)

        // Test finding by name fallback
        let safariURL = manager.findApplicationURL(bundleId: "invalid.bundle.id", name: "Safari")
        XCTAssertNotNil(safariURL)

        // Test clean icon extraction
        if let termURL = terminalURL {
            let cleanIcon = manager.extractCleanIcon(from: termURL.path, pointSize: 32.0)
            XCTAssertNotNil(cleanIcon)
            XCTAssertEqual(cleanIcon.size.width, 32.0)
            XCTAssertEqual(cleanIcon.size.height, 32.0)
        }

        // Test cached access
        let icon1 = manager.icon(for: "com.apple.Terminal", name: "Terminal")
        XCTAssertNotNil(icon1)
        let icon2 = manager.icon(for: "com.apple.Terminal", name: "Terminal")
        XCTAssertNotNil(icon2)
        XCTAssertEqual(icon1, icon2)
    }

    func testQRCodeGeneratorValidOutput() {
        let testURL = "http://192.168.1.3:8080/?auto=1"
        let qrImage = QRCodeGenerator.generate(from: testURL, size: 150)
        XCTAssertNotNil(qrImage)
        XCTAssertEqual(qrImage?.size.width, 150)
        XCTAssertEqual(qrImage?.size.height, 150)

        let smallQR = QRCodeGenerator.generate(from: "http://192.168.1.3:8080/NotchDeck.apk", size: 80, correctionLevel: "Q")
        XCTAssertNotNil(smallQR)
        XCTAssertEqual(smallQR?.size.width, 80)
    }

    func testNetworkHelperLocalIPAddress() {
        let ip = NetworkHelper.localIPAddress
        XCTAssertFalse(ip.isEmpty)
        XCTAssertFalse(ip.contains("127.0.0.1"))
    }

    func testQRCodeCardViewAndTargetModes() {
        XCTAssertEqual(DownloadTargetMode.allCases.count, 3)
        XCTAssertEqual(DownloadTargetMode.autoPortal.title, "Auto-Download (Recommended)")
        XCTAssertEqual(DownloadTargetMode.directApk.title, "Direct APK")
        XCTAssertEqual(DownloadTargetMode.portalPage.title, "Portal Page")

        let cardView = QRCodeCardView()
        XCTAssertNotNil(cardView.body)

        let hosting = NSHostingView(rootView: cardView)
        hosting.layout()
        XCTAssertNotNil(hosting)

        let guide = StepMiniGuide(num: "1", title: "Scan", desc: "Camera")
        let guideHosting = NSHostingView(rootView: guide)
        guideHosting.layout()
        XCTAssertNotNil(guideHosting)
    }
}



