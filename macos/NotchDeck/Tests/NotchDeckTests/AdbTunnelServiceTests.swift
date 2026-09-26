import XCTest
@testable import NotchDeck

final class AdbTunnelServiceTests: XCTestCase {
    func testAdbTunnelServiceLifecycle() {
        let service = AdbTunnelService.shared
        service.start()
        service.stop()
    }

    func testLocateAdbReturnsPathOrNil() {
        let service = AdbTunnelService.shared
        if let path = service.locateAdb() {
            XCTAssertTrue(FileManager.default.isExecutableFile(atPath: path))
        }
    }

    func testCheckAndSetupTunnelsSafeExecution() {
        let service = AdbTunnelService.shared
        // Ensure running checkAndSetupTunnels() is safe and does not crash
        service.checkAndSetupTunnels()
    }
}
