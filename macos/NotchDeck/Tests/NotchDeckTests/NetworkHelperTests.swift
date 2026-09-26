import XCTest
@testable import NotchDeck

final class NetworkHelperTests: XCTestCase {
    func testNetworkHelperDefaultInstance() {
        let helper = NetworkHelper.shared
        XCTAssertFalse(helper.activeIPAddress.isEmpty)
        XCTAssertFalse(helper.activeIPAddress.hasPrefix("127."))
        XCTAssertFalse(helper.activeIPAddress.hasPrefix("169.254."))
    }

    func testAvailableInterfacesDiscovery() {
        let helper = NetworkHelper.shared
        let interfaces = helper.availableInterfaces
        XCTAssertFalse(interfaces.isEmpty, "Should discover at least one active network interface")

        for iface in interfaces {
            XCTAssertFalse(iface.id.isEmpty)
            XCTAssertFalse(iface.name.isEmpty)
            XCTAssertFalse(iface.ip.isEmpty)
            XCTAssertFalse(iface.ip.hasPrefix("127."))
            XCTAssertFalse(iface.ip.hasPrefix("169.254."))
            XCTAssertFalse(iface.displayName.isEmpty)
        }
    }

    func testInterfaceSelectionAndFallback() {
        let helper = NetworkHelper.shared
        let originalIP = helper.activeIPAddress
        let interfaces = helper.availableInterfaces
        guard let first = interfaces.first else { return }

        helper.selectInterface(id: first.id)
        XCTAssertEqual(helper.selectedInterfaceId, first.id)
        XCTAssertEqual(helper.activeIPAddress, first.ip)

        // Reset to auto
        helper.selectInterface(id: nil)
        XCTAssertNil(helper.selectedInterfaceId)
        XCTAssertEqual(helper.activeIPAddress, originalIP)
    }

    func testStaticLocalIPAddressCompatibility() {
        let staticIP = NetworkHelper.localIPAddress
        let sharedIP = NetworkHelper.shared.activeIPAddress
        XCTAssertEqual(staticIP, sharedIP)
    }

    func testNetworkRefresh() {
        let helper = NetworkHelper.shared
        helper.refresh()
        XCTAssertFalse(helper.activeIPAddress.isEmpty)
    }

    func testSystemControlServiceValues() {
        let systemControl = SystemControlService.shared
        let volume = systemControl.getOutputVolume()
        XCTAssertTrue(volume >= 0 && volume <= 100)

        let brightness = systemControl.getBrightness()
        XCTAssertTrue(brightness >= 0.0 && brightness <= 1.0)

        let devices = systemControl.getAudioOutputDevices()
        XCTAssertFalse(devices.isEmpty)

        let defaultDevice = systemControl.getDefaultAudioOutputDevice()
        XCTAssertFalse(defaultDevice.isEmpty)
    }

    func testPhoneDeckHostServerBuildSystemStatus() {
        let hostServer = PhoneDeckHostServer.shared
        let status = hostServer.buildSystemStatus()

        XCTAssertEqual(status["type"] as? String, "system.status")
        XCTAssertEqual(status["protocolVersion"] as? Int, 1)

        guard let payload = status["payload"] as? [String: Any] else {
            XCTFail("Missing payload in system.status")
            return
        }

        XCTAssertNotNil(payload["volume"])
        XCTAssertNotNil(payload["brightness"])
        XCTAssertNotNil(payload["isWifiOn"])
        XCTAssertNotNil(payload["isBluetoothOn"])
        XCTAssertNotNil(payload["audioDevices"])
        XCTAssertNotNil(payload["currentAudioDevice"])
    }
}

