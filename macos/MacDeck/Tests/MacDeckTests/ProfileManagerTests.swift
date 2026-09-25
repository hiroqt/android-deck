import XCTest
@testable import MacDeck

final class ProfileManagerTests: XCTestCase {
    func testProfileManagerDetectsFileChanges() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let profileURL = tempDir.appendingPathComponent("profile.json")

        let initialProfile = StoredProfile(
            revision: 1,
            name: "Initial Deck",
            slots: [
                StoredAppSlot(id: "app-1", label: "Initial App", bundleId: "com.apple.Terminal")
            ]
        )
        let initialData = try JSONEncoder().encode(initialProfile)
        try initialData.write(to: profileURL)

        let manager = ProfileManager(configURL: profileURL)
        defer {
            manager.stopWatchers()
            manager.onProfileChanged = nil
        }

        let initialSnapshot = manager.getCurrentProfileSnapshot()
        XCTAssertEqual(initialSnapshot.controls.first?.label, "Initial App")

        // Expectation for onProfileChanged
        let changeExpectation = expectation(description: "onProfileChanged fired")
        final class FulfillGuard: @unchecked Sendable {
            private let lock = NSLock()
            private var fulfilled = false
            func runOnce(_ block: () -> Void) {
                lock.lock()
                defer { lock.unlock() }
                if !fulfilled {
                    fulfilled = true
                    block()
                }
            }
        }
        let guardBox = FulfillGuard()
        manager.onProfileChanged = { snapshot in
            if snapshot.controls.first?.label == "Updated App" {
                guardBox.runOnce {
                    changeExpectation.fulfill()
                }
            }
        }

        // Simulate atomic write replacement (similar to PhoneDeckService / NotchDeck)
        let updatedProfile = StoredProfile(
            revision: 2,
            name: "Updated Deck",
            slots: [
                StoredAppSlot(id: "app-1", label: "Updated App", bundleId: "com.apple.Safari")
            ]
        )
        let updatedData = try JSONEncoder().encode(updatedProfile)
        try updatedData.write(to: profileURL, options: .atomic)

        wait(for: [changeExpectation], timeout: 2.5)
        manager.onProfileChanged = nil

        let updatedSnapshot = manager.getCurrentProfileSnapshot()
        XCTAssertEqual(updatedSnapshot.controls.first?.label, "Updated App")
    }

    func testProfileManagerManualReloadFromDisk() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let profileURL = tempDir.appendingPathComponent("profile.json")

        let initialProfile = StoredProfile(
            revision: 1,
            name: "Deck",
            slots: [
                StoredAppSlot(id: "app-1", label: "App One", bundleId: "com.apple.Terminal")
            ]
        )
        try JSONEncoder().encode(initialProfile).write(to: profileURL)

        let manager = ProfileManager(configURL: profileURL)
        defer { manager.stopWatchers() }

        // Update file on disk
        let updatedProfile = StoredProfile(
            revision: 5,
            name: "Deck",
            slots: [
                StoredAppSlot(id: "app-1", label: "App Two", bundleId: "com.apple.Safari")
            ]
        )
        try JSONEncoder().encode(updatedProfile).write(to: profileURL)

        manager.reloadFromDisk()

        let snapshot = manager.getCurrentProfileSnapshot()
        XCTAssertEqual(snapshot.controls.first?.label, "App Two")
    }
}
