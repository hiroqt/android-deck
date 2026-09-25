import Foundation

public struct StoredAppSlot: Codable {
    public var id: String
    public var label: String
    public var bundleId: String

    public init(id: String, label: String, bundleId: String) {
        self.id = id
        self.label = label
        self.bundleId = bundleId
    }
}

public struct StoredProfile: Codable {
    public var revision: Int
    public var name: String
    public var slots: [StoredAppSlot]

    public init(revision: Int = 1, name: String = "My Deck", slots: [StoredAppSlot]) {
        self.revision = revision
        self.name = name
        self.slots = slots
    }
}

public final class ProfileManager: @unchecked Sendable {
    public static let shared = ProfileManager()

    private let configURL: URL
    private var profile: StoredProfile
    private let lock = NSLock()

    public var onProfileChanged: (@Sendable (ProfileSnapshotPayload) -> Void)?

    public init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dir = home.appendingPathComponent(".macdeck", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.configURL = dir.appendingPathComponent("profile.json")

        if let data = try? Data(contentsOf: configURL),
           let loaded = try? JSONDecoder().decode(StoredProfile.self, from: data) {
            self.profile = loaded
        } else {
            self.profile = ProfileManager.defaultProfile()
            ProfileManager.saveProfile(self.profile, to: configURL)
        }
    }

    public static func defaultProfile() -> StoredProfile {
        let scanner = AppScanner.shared
        var slots: [StoredAppSlot] = []

        // Try to pick sensible defaults that exist on the machine
        let candidateApps = [
            ("com.microsoft.VSCode", "VS Code"),
            ("com.apple.Terminal", "Terminal"),
            ("com.google.Chrome", "Chrome"),
            ("com.apple.Safari", "Safari"),
            ("com.apple.finder", "Finder"),
            ("com.apple.systempreferences", "Settings"),
            ("com.apple.Music", "Music"),
            ("com.apple.Notes", "Notes")
        ]

        var index = 1
        for (bundleId, fallbackName) in candidateApps {
            if scanner.url(forBundleId: bundleId) != nil || bundleId == "com.apple.finder" {
                slots.append(StoredAppSlot(id: "app-\(index)", label: fallbackName, bundleId: bundleId))
                index += 1
                if slots.count == 6 { break }
            }
        }

        // Fill remaining slots if fewer than 6 found
        while slots.count < 6 {
            slots.append(StoredAppSlot(id: "app-\(index)", label: "App \(index)", bundleId: "com.apple.Terminal"))
            index += 1
        }

        return StoredProfile(revision: 1, name: "Main Deck", slots: slots)
    }

    private static func saveProfile(_ profile: StoredProfile, to url: URL) {
        if let data = try? JSONEncoder().encode(profile) {
            try? data.write(to: url)
        }
    }

    public func getCurrentProfileSnapshot() -> ProfileSnapshotPayload {
        lock.lock()
        defer { lock.unlock() }

        let scanner = AppScanner.shared
        let controls = profile.slots.map { slot -> DeckControl in
            let iconBase64 = scanner.getAppIconBase64(bundleId: slot.bundleId)
            return DeckControl(
                id: slot.id,
                label: slot.label,
                bundleId: slot.bundleId,
                iconPngBase64: iconBase64
            )
        }

        return ProfileSnapshotPayload(
            id: "main-deck",
            name: profile.name,
            revision: profile.revision,
            maxColumns: 3,
            maxRows: 3,
            controls: controls
        )
    }

    public func updateSlot(index: Int, app: InstalledApp) {
        lock.lock()
        guard index >= 0 && index < profile.slots.count else {
            lock.unlock()
            return
        }

        profile.slots[index].label = app.name
        profile.slots[index].bundleId = app.bundleId
        profile.revision += 1
        ProfileManager.saveProfile(profile, to: configURL)
        lock.unlock()

        let snapshot = getCurrentProfileSnapshot()
        onProfileChanged?(snapshot)
    }

    public func getStoredSlots() -> [StoredAppSlot] {
        lock.lock()
        defer { lock.unlock() }
        return profile.slots
    }

    public func getBundleId(for controlId: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return profile.slots.first { $0.id == controlId }?.bundleId
    }
}
