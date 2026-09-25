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
