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

    func testActionRouterHandlesUnknownMediaTargetGracefully() {
        let service = ActionExecutionService()
        let slot = DeckSlot(index: 0, title: "InvalidMedia", actionType: .mediaControl, target: "invalidMediaCommand")
        let result = service.execute(slot: slot)
        XCTAssertFalse(result)
    }

    func testActionRouterShellScriptValidation() {
        let service = ActionExecutionService()
        let emptySlot = DeckSlot(index: 0, title: "EmptyShell", actionType: .shellScript, target: "")
        XCTAssertFalse(service.execute(slot: emptySlot))

        let whitespaceSlot = DeckSlot(index: 1, title: "WhitespaceShell", actionType: .shellScript, target: "   \n\t  ")
        XCTAssertFalse(service.execute(slot: whitespaceSlot))

        let validSlot = DeckSlot(index: 2, title: "ValidShell", actionType: .shellScript, target: "echo 'NotchDeck test'")
        XCTAssertTrue(service.execute(slot: validSlot))
    }

    func testActionRouterAppLauncherHandlesInvalidBundleId() {
        let service = ActionExecutionService()
        let slot = DeckSlot(index: 0, title: "InvalidApp", actionType: .appLauncher, target: "com.invalid.nonexistent.app.bundle.id.xyz")
        let result = service.execute(slot: slot)
        XCTAssertFalse(result)
    }

    func testActionRouterURLBookmarkHandlesInvalidURL() {
        let service = ActionExecutionService()
        let slot = DeckSlot(index: 0, title: "InvalidURL", actionType: .urlBookmark, target: "")
        let result = service.execute(slot: slot)
        XCTAssertFalse(result)
    }

    func testAppScannerReturnsUniqueAndSortedApps() {
        let scanner = AppScannerService()
        let apps = scanner.scanInstalledApps()
        
        var seen = Set<String>()
        for app in apps {
            XCTAssertFalse(seen.contains(app.bundleIdentifier), "Duplicate bundle ID found: \(app.bundleIdentifier)")
            seen.insert(app.bundleIdentifier)
        }

        for i in 0..<max(0, apps.count - 1) {
            let comparison = apps[i].name.localizedCaseInsensitiveCompare(apps[i + 1].name)
            XCTAssertTrue(comparison == .orderedAscending || comparison == .orderedSame,
                          "Apps are not sorted: \(apps[i].name) vs \(apps[i + 1].name)")
        }
    }

    func testSystemControlAudioAndVolumeMethods() {
        let systemControl = SystemControlService.shared
        let devices = systemControl.getAudioOutputDevices()
        XCTAssertFalse(devices.isEmpty, "Should find at least one audio output device on Mac")

        let defaultDevice = systemControl.getDefaultAudioOutputDevice()
        XCTAssertFalse(defaultDevice.isEmpty, "Should get active audio device")

        let vol = systemControl.getOutputVolume()
        XCTAssertTrue(vol >= 0 && vol <= 100, "Volume should be between 0 and 100")

        systemControl.setOutputVolume(75)
    }

    func testSystemControlBrightness() {
        let systemControl = SystemControlService.shared
        let brightness = systemControl.getBrightness()
        XCTAssertTrue(brightness >= 0.0 && brightness <= 1.0, "Brightness should be between 0.0 and 1.0")
    }
}

