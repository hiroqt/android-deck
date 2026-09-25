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

    func testConfigManagerUpdatesSlot() throws {
        let configFile = tempDirectory.appendingPathComponent("config.json")
        let manager = ConfigManager(fileURL: configFile)
        var slotToUpdate = manager.config.slots[1]
        slotToUpdate.title = "Updated Safari"
        slotToUpdate.target = "https://example.com"
        slotToUpdate.actionType = .urlBookmark

        manager.updateSlot(slotToUpdate)

        XCTAssertEqual(manager.config.slots[1].title, "Updated Safari")
        XCTAssertEqual(manager.config.slots[1].target, "https://example.com")
        XCTAssertEqual(manager.config.slots[1].actionType, .urlBookmark)

        let reloaded = manager.loadConfig()
        XCTAssertEqual(reloaded.slots[1].title, "Updated Safari")
    }

    func testConfigManagerResetToDefault() throws {
        let configFile = tempDirectory.appendingPathComponent("config.json")
        let manager = ConfigManager(fileURL: configFile)
        var config = manager.loadConfig()
        config.slots[0].title = "Modified Slot"
        try manager.saveConfig(config)
        XCTAssertEqual(manager.config.slots[0].title, "Modified Slot")

        manager.resetToDefault()

        XCTAssertEqual(manager.config.slots[0].title, "Finder")
        let reloaded = manager.loadConfig()
        XCTAssertEqual(reloaded.slots[0].title, "Finder")
    }

    func testConfigManagerHandlesCorruptedFileGracefully() throws {
        let configFile = tempDirectory.appendingPathComponent("config.json")
        try "invalid json content { [".write(to: configFile, atomically: true, encoding: .utf8)

        let manager = ConfigManager(fileURL: configFile)
        let config = manager.loadConfig()
        XCTAssertEqual(config.slots.count, 10)
        XCTAssertEqual(config.slots[0].title, "Finder")
    }

    func testConfigManagerCreatesParentDirectoryIfNeeded() throws {
        let nestedDir = tempDirectory.appendingPathComponent("nested/deep/directory")
        let configFile = nestedDir.appendingPathComponent("config.json")
        let manager = ConfigManager(fileURL: configFile)

        var config = NotchDeckConfig.defaultConfig()
        config.slots[0].title = "Deep Config"
        try manager.saveConfig(config)

        XCTAssertTrue(FileManager.default.fileExists(atPath: configFile.path))
        let reloaded = manager.loadConfig()
        XCTAssertEqual(reloaded.slots[0].title, "Deep Config")
    }

    func testConfigManagerConformsToProtocol() {
        let configFile = tempDirectory.appendingPathComponent("config.json")
        let manager: ConfigManagerProtocol = ConfigManager(fileURL: configFile)
        XCTAssertEqual(manager.config.slots.count, 10)
    }
}
