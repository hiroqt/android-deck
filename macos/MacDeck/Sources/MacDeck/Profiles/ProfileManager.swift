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

    private var fileWatcher: DispatchSourceFileSystemObject?
    private var dirWatcher: DispatchSourceFileSystemObject?
    private var pollTimer: DispatchSourceTimer?
    private var lastModificationDate: Date?

    public init(configURL: URL? = nil) {
        if let configURL = configURL {
            self.configURL = configURL
        } else {
            let home = FileManager.default.homeDirectoryForCurrentUser
            let dir = home.appendingPathComponent(".macdeck", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.configURL = dir.appendingPathComponent("profile.json")
        }

        if let data = try? Data(contentsOf: self.configURL),
           let loaded = try? JSONDecoder().decode(StoredProfile.self, from: data) {
            self.profile = loaded
            if let attrs = try? FileManager.default.attributesOfItem(atPath: self.configURL.path) {
                self.lastModificationDate = attrs[.modificationDate] as? Date
            }
        } else {
            self.profile = ProfileManager.defaultProfile()
            ProfileManager.saveProfile(self.profile, to: self.configURL)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: self.configURL.path) {
                self.lastModificationDate = attrs[.modificationDate] as? Date
            }
        }

        startWatchingConfigFile()
        startWatchingDirectory()
        startPollingTimer()
    }

    deinit {
        stopWatchers()
    }

    private var debounceWorkItem: DispatchWorkItem?

    public func stopWatchers() {
        lock.lock()
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        lock.unlock()

        pollTimer?.cancel()
        pollTimer = nil

        fileWatcher?.cancel()
        fileWatcher = nil

        dirWatcher?.cancel()
        dirWatcher = nil
    }

    private func scheduleReload() {
        lock.lock()
        debounceWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.startWatchingConfigFile()
            self?.reloadFromDisk()
        }
        debounceWorkItem = item
        lock.unlock()
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.05, execute: item)
    }

    private func startWatchingConfigFile() {
        fileWatcher?.cancel()
        fileWatcher = nil

        let fd = open(configURL.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .rename, .delete, .attrib],
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            self?.scheduleReload()
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        self.fileWatcher = source
    }

    private func startWatchingDirectory() {
        let dirURL = configURL.deletingLastPathComponent()
        let fd = open(dirURL.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .attrib],
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            // Parent directory modified (e.g. atomic write replacement or file created)
            self?.scheduleReload()
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        self.dirWatcher = source
    }

    private func startPollingTimer() {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            self?.checkModificationDateAndReloadIfNeeded()
        }
        timer.resume()
        self.pollTimer = timer
    }

    private func checkModificationDateAndReloadIfNeeded() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: configURL.path),
              let modDate = attrs[.modificationDate] as? Date else {
            return
        }

        lock.lock()
        let prev = lastModificationDate
        lock.unlock()

        if prev == nil || modDate > prev! {
            reloadFromDisk()
        }
    }

    public func reloadFromDisk() {
        var loadedProfile: StoredProfile?
        var newModDate: Date?

        for _ in 0..<3 {
            if let data = try? Data(contentsOf: configURL),
               let loaded = try? JSONDecoder().decode(StoredProfile.self, from: data) {
                loadedProfile = loaded
                if let attrs = try? FileManager.default.attributesOfItem(atPath: configURL.path) {
                    newModDate = attrs[.modificationDate] as? Date
                }
                break
            }
            usleep(30_000) // 30ms backoff in case file write is in progress
        }

        guard let loaded = loadedProfile else { return }

        lock.lock()
        let oldSlots = self.profile.slots
        let newSlots = loaded.slots
        let changed = oldSlots.count != newSlots.count || zip(oldSlots, newSlots).contains {
            $0.id != $1.id || $0.label != $1.label || $0.bundleId != $1.bundleId
        }

        self.profile = loaded
        if changed {
            self.profile.revision += 1
        }
        if let mod = newModDate {
            self.lastModificationDate = mod
        }
        print("🔄 [MacDeck] Reloaded profile from disk: \(loaded.slots.map { $0.label }.joined(separator: ", "))")
        lock.unlock()

        let snapshot = getCurrentProfileSnapshot()
        onProfileChanged?(snapshot)
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
        if let attrs = try? FileManager.default.attributesOfItem(atPath: configURL.path) {
            self.lastModificationDate = attrs[.modificationDate] as? Date
        }
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
