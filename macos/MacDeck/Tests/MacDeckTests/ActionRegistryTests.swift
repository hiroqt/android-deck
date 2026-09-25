import XCTest
@testable import MacDeck

final class ActionRegistryTests: XCTestCase {
    func testUnknownActionFailsClosed() async {
        let registry = ActionRegistry.shared
        let result = await registry.invoke(controlId: "nonexistent-action-id", event: "tap")

        XCTAssertEqual(result.status, "ERROR")
        XCTAssertEqual(result.errorCode, "ACTION_UNKNOWN")
    }

    func testAppScannerCanScanApps() {
        let scanner = AppScanner.shared
        let apps = scanner.scanInstalledApps()
        XCTAssertFalse(apps.isEmpty, "Should find at least some macOS applications in /Applications or /System/Applications")
    }

    func testSystemControlGetAudioDevices() {
        let devices = SystemControlAction.getAvailableAudioOutputDevices()
        XCTAssertFalse(devices.isEmpty, "Should detect at least one audio output device on macOS")
    }

    func testSystemControlVolumeInvoke() async {
        let registry = ActionRegistry.shared
        let result = await registry.invoke(controlId: "sys_volume", event: "set:75")
        XCTAssertEqual(result.status, "OK")
    }

    func testSystemControlAudioDeviceSelect() async {
        let registry = ActionRegistry.shared
        let devices = SystemControlAction.getAvailableAudioOutputDevices()
        guard let first = devices.first else { return }

        let result = await registry.invoke(controlId: "sys_audio_device", event: "select:\(first.name)")
        XCTAssertEqual(result.status, "OK")

        let invalidResult = await registry.invoke(controlId: "sys_audio_device", event: "select:NON_EXISTENT_AUDIO_DEVICE_9999")
        XCTAssertEqual(invalidResult.status, "ERROR")
        XCTAssertEqual(invalidResult.errorCode, "DEVICE_NOT_FOUND")
    }
}

