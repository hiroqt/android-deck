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
}
