import XCTest
@testable import MacDeck

final class ProtocolTests: XCTestCase {
    func testHelloEncodingAndDecoding() throws {
        let hello = Envelope(
            type: "hello",
            payload: HelloPayload(clientName: "Pixel 7 Pro", platform: "Android", appVersion: "1.0.0")
        )
        let data = try JSONEncoder().encode(hello)
        let decoded = try JSONDecoder().decode(Envelope<HelloPayload>.self, from: data)

        XCTAssertEqual(decoded.type, "hello")
        XCTAssertEqual(decoded.protocolVersion, 1)
        XCTAssertEqual(decoded.payload.clientName, "Pixel 7 Pro")
    }

    func testActionInvokeEncodingAndDecoding() throws {
        let invoke = Envelope(
            type: "action.invoke",
            payload: ActionInvokePayload(controlId: "app-1", event: "tap")
        )
        let data = try JSONEncoder().encode(invoke)
        let decoded = try JSONDecoder().decode(Envelope<ActionInvokePayload>.self, from: data)

        XCTAssertEqual(decoded.type, "action.invoke")
        XCTAssertEqual(decoded.payload.controlId, "app-1")
        XCTAssertEqual(decoded.payload.event, "tap")
    }

    func testProfileSnapshotDecoding() throws {
        let controls = [
            DeckControl(id: "app-1", label: "VS Code", bundleId: "com.microsoft.VSCode", iconPngBase64: "dummyBase64")
        ]
        let snapshot = ProfileSnapshotPayload(
            id: "main-deck",
            name: "My Apps",
            revision: 1,
            maxColumns: 3,
            maxRows: 3,
            controls: controls
        )
        let envelope = Envelope(type: "profile.snapshot", payload: snapshot)
        let data = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(Envelope<ProfileSnapshotPayload>.self, from: data)

        XCTAssertEqual(decoded.payload.controls.count, 1)
        XCTAssertEqual(decoded.payload.controls.first?.label, "VS Code")
    }
}
