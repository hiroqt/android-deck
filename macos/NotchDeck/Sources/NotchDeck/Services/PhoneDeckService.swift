import Foundation
import AppKit

public struct PhoneDeckSlot: Identifiable, Equatable, Codable {
    public var id: String // "app-1" ... "app-6"
    public var index: Int  // 0 ... 5
    public var label: String
    public var bundleId: String

    public init(id: String, index: Int, label: String, bundleId: String) {
        self.id = id
        self.index = index
        self.label = label
        self.bundleId = bundleId
    }

    public var isEmpty: Bool {
        return bundleId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || bundleId == "empty"
    }
}

public struct DeviceStatusInfo: Codable, Equatable {
    public var connected: Bool
    public var clientName: String?
    public var clientCount: Int
    public var port: UInt16
    public var timestamp: Double
    public var batteryLevel: Int?
    public var isCharging: Bool?

    public init(
        connected: Bool = false,
        clientName: String? = nil,
        clientCount: Int = 0,
        port: UInt16 = 8765,
        timestamp: Double = Date().timeIntervalSince1970,
        batteryLevel: Int? = nil,
        isCharging: Bool? = nil
    ) {
        self.connected = connected
        self.clientName = clientName
        self.clientCount = clientCount
        self.port = port
        self.timestamp = timestamp
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
    }
}

public final class PhoneDeckService: ObservableObject {
    public static let shared = PhoneDeckService()

    private let profileURL: URL
    private let statusURL: URL
    private let presetsURL: URL

    @Published public private(set) var slots: [PhoneDeckSlot] = []
    @Published public private(set) var presets: [DeckPreset] = []
    @Published public private(set) var activePresetId: UUID? = nil
    @Published public private(set) var isDeviceConnected: Bool = false
    @Published public private(set) var connectedDeviceName: String? = nil
    @Published public private(set) var clientCount: Int = 0
    @Published public private(set) var batteryLevel: Int? = nil
    @Published public private(set) var isCharging: Bool = false
    @Published public private(set) var isPortalOnline: Bool = false

    private var profileWatcher: DispatchSourceFileSystemObject?
    private var statusWatcher: DispatchSourceFileSystemObject?
    private var pollTimer: Timer?

    public init(baseDirectory: URL? = nil) {
        let dir: URL
        if let baseDirectory = baseDirectory {
            dir = baseDirectory
        } else {
            let home = FileManager.default.homeDirectoryForCurrentUser
            let notchDir = home.appendingPathComponent(".notchdeck", isDirectory: true)
            let macDir = home.appendingPathComponent(".macdeck", isDirectory: true)
            if FileManager.default.fileExists(atPath: notchDir.path) {
                dir = notchDir
            } else if FileManager.default.fileExists(atPath: macDir.path) {
                dir = notchDir
                try? FileManager.default.createDirectory(at: notchDir, withIntermediateDirectories: true)
                for file in ["profile.json", "status.json", "presets.json"] {
                    let src = macDir.appendingPathComponent(file)
                    let dst = notchDir.appendingPathComponent(file)
                    if FileManager.default.fileExists(atPath: src.path) && !FileManager.default.fileExists(atPath: dst.path) {
                        try? FileManager.default.copyItem(at: src, to: dst)
                    }
                }
            } else {
                dir = notchDir
            }
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.profileURL = dir.appendingPathComponent("profile.json")
        self.statusURL = dir.appendingPathComponent("status.json")
        self.presetsURL = dir.appendingPathComponent("presets.json")

        loadProfile()
        loadPresets()
        loadStatus()
        startWatchers()
    }

    deinit {
        pollTimer?.invalidate()
        profileWatcher?.cancel()
        statusWatcher?.cancel()
    }

    public func loadProfile() {
        if let data = try? Data(contentsOf: profileURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let rawSlots = json["slots"] as? [[String: Any]] {

            var parsedSlots: [PhoneDeckSlot] = []
            for i in 0..<6 {
                let slotId = "app-\(i + 1)"
                if i < rawSlots.count {
                    let s = rawSlots[i]
                    let label = s["label"] as? String ?? ""
                    let bundleId = s["bundleId"] as? String ?? ""
                    let id = s["id"] as? String ?? slotId
                    parsedSlots.append(PhoneDeckSlot(id: id, index: i, label: label, bundleId: bundleId))
                } else {
                    parsedSlots.append(PhoneDeckSlot(id: slotId, index: i, label: "", bundleId: ""))
                }
            }
            DispatchQueue.main.async {
                self.slots = parsedSlots
            }
        } else {
            // Default 6 slots
            let defaultSlots: [PhoneDeckSlot] = [
                PhoneDeckSlot(id: "app-1", index: 0, label: "VS Code", bundleId: "com.microsoft.VSCode"),
                PhoneDeckSlot(id: "app-2", index: 1, label: "Terminal", bundleId: "com.apple.Terminal"),
                PhoneDeckSlot(id: "app-3", index: 2, label: "Safari", bundleId: "com.apple.Safari"),
                PhoneDeckSlot(id: "app-4", index: 3, label: "Finder", bundleId: "com.apple.finder"),
                PhoneDeckSlot(id: "app-5", index: 4, label: "Music", bundleId: "com.apple.Music"),
                PhoneDeckSlot(id: "app-6", index: 5, label: "Settings", bundleId: "com.apple.systempreferences")
            ]
            saveProfile(defaultSlots)
            DispatchQueue.main.async {
                self.slots = defaultSlots
            }
        }
    }

    public func loadStatus() {
        guard let data = try? Data(contentsOf: statusURL),
              let status = try? JSONDecoder().decode(DeviceStatusInfo.self, from: data) else {
            DispatchQueue.main.async {
                self.isDeviceConnected = false
                self.connectedDeviceName = nil
                self.clientCount = 0
                self.batteryLevel = nil
                self.isCharging = false
            }
            return
        }

        let apply = {
            self.isDeviceConnected = status.connected && status.clientCount > 0
            self.connectedDeviceName = status.clientName
            self.clientCount = status.clientCount
            self.batteryLevel = self.isDeviceConnected ? status.batteryLevel : nil
            self.isCharging = self.isDeviceConnected ? (status.isCharging ?? false) : false
        }
        if Thread.isMainThread {
            apply()
        } else {
            DispatchQueue.main.async(execute: apply)
        }
    }

    public func setSlotApp(index: Int, app: InstalledAppInfo) {
        guard index >= 0 && index < 6 else { return }
        var current = slots
        while current.count < 6 {
            current.append(PhoneDeckSlot(id: "app-\(current.count + 1)", index: current.count, label: "", bundleId: ""))
        }
        current[index].label = app.name
        current[index].bundleId = app.bundleIdentifier
        saveProfile(current)
    }

    public func clearSlot(index: Int) {
        guard index >= 0 && index < slots.count else { return }
        var current = slots
        current[index].label = ""
        current[index].bundleId = ""
        saveProfile(current)
    }

    public func saveProfile(_ newSlots: [PhoneDeckSlot]) {
        var slotDicts: [[String: Any]] = []
        for (i, slot) in newSlots.enumerated() {
            slotDicts.append([
                "id": "app-\(i + 1)",
                "label": slot.label,
                "bundleId": slot.bundleId
            ])
        }

        var currentRevision = 1
        if let data = try? Data(contentsOf: profileURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let rev = json["revision"] as? Int {
            currentRevision = rev + 1
        }

        let profileDict: [String: Any] = [
            "name": "Main Deck",
            "revision": currentRevision,
            "slots": slotDicts
        ]

        if let data = try? JSONSerialization.data(withJSONObject: profileDict, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: profileURL, options: .atomic)
        }

        DispatchQueue.main.async {
            self.slots = newSlots
        }
    }

    public func resetDefaults() {
        let defaults: [PhoneDeckSlot] = [
            PhoneDeckSlot(id: "app-1", index: 0, label: "VS Code", bundleId: "com.microsoft.VSCode"),
            PhoneDeckSlot(id: "app-2", index: 1, label: "Terminal", bundleId: "com.apple.Terminal"),
            PhoneDeckSlot(id: "app-3", index: 2, label: "Safari", bundleId: "com.apple.Safari"),
            PhoneDeckSlot(id: "app-4", index: 3, label: "Finder", bundleId: "com.apple.finder"),
            PhoneDeckSlot(id: "app-5", index: 4, label: "Music", bundleId: "com.apple.Music"),
            PhoneDeckSlot(id: "app-6", index: 5, label: "Settings", bundleId: "com.apple.systempreferences")
        ]
        saveProfile(defaults)
    }

    // MARK: - Presets Management

    public func loadPresets() {
        if let data = try? Data(contentsOf: presetsURL),
           let saved = try? JSONDecoder().decode([DeckPreset].self, from: data),
           !saved.isEmpty {
            DispatchQueue.main.async {
                self.presets = saved
                if self.activePresetId == nil {
                    self.activePresetId = saved.first?.id
                }
            }
        } else {
            let defaults = DeckPreset.defaultPresets()
            savePresetsToDisk(defaults)
            DispatchQueue.main.async {
                self.presets = defaults
                self.activePresetId = defaults.first?.id
            }
        }
    }

    public func savePresetsToDisk(_ list: [DeckPreset]) {
        if let data = try? JSONEncoder().encode(list) {
            try? data.write(to: presetsURL, options: .atomic)
        }
        DispatchQueue.main.async {
            self.presets = list
        }
    }

    public func applyPreset(id: UUID) {
        guard let target = presets.first(where: { $0.id == id }) else { return }
        self.activePresetId = id
        saveProfile(target.slots)
    }

    public func saveCurrentAsPreset(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let presetName = trimmed.isEmpty ? "Preset \(presets.count + 1)" : trimmed
        var currentSlots = self.slots
        while currentSlots.count < 6 {
            let idx = currentSlots.count
            currentSlots.append(PhoneDeckSlot(id: "app-\(idx + 1)", index: idx, label: "", bundleId: ""))
        }
        let newPreset = DeckPreset(name: presetName, slots: Array(currentSlots.prefix(6)))
        var updated = presets
        updated.append(newPreset)
        self.activePresetId = newPreset.id
        savePresetsToDisk(updated)
    }

    public func deletePreset(id: UUID) {
        var updated = presets.filter { $0.id != id }
        if updated.isEmpty {
            updated = DeckPreset.defaultPresets()
        }
        if activePresetId == id {
            activePresetId = updated.first?.id
        }
        savePresetsToDisk(updated)
    }

    public func renamePreset(id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var updated = presets
        if let idx = updated.firstIndex(where: { $0.id == id }) {
            updated[idx].name = trimmed
            savePresetsToDisk(updated)
        }
    }

    private var lastProfileModDate: Date?

    private func checkProfileModification() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: profileURL.path),
              let mod = attrs[.modificationDate] as? Date else { return }
        if lastProfileModDate == nil || mod > lastProfileModDate! {
            lastProfileModDate = mod
            loadProfile()
        }
    }

    private func startWatchers() {
        // Watch profile.json
        startFileWatcher(for: profileURL) { [weak self] in
            self?.loadProfile()
        }

        // Watch status.json
        startFileWatcher(for: statusURL) { [weak self] in
            self?.loadStatus()
        }

        // Timer backup to keep connection status and profile fresh
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
                self?.loadStatus()
                self?.checkProfileModification()
                self?.checkPortalStatus()
            }
        }
        checkPortalStatus()
    }

    public func checkPortalStatus(completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: "http://127.0.0.1:8080/api/status") else {
            completion?(false)
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.0
        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            let isOnline = (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async {
                self?.isPortalOnline = isOnline
                completion?(isOnline)
            }
        }.resume()
    }

    public func startPortalServerIfNeeded() {
        checkPortalStatus { [weak self] alreadyOnline in
            if alreadyOnline { return }

            let candidates = [
                URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("scripts/serve_portal.py").path,
                URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("../scripts/serve_portal.py").path,
                URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("../../scripts/serve_portal.py").path,
                "/Users/arnel/android-deck/scripts/serve_portal.py"
            ]

            guard let script = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
                return
            }

            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            task.arguments = [script]
            try? task.run()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self?.checkPortalStatus()
            }
        }
    }

    private func startFileWatcher(for url: URL, onChange: @escaping () -> Void) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .rename, .delete, .attrib],
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            let flags = source.data
            if flags.contains(.delete) || flags.contains(.rename) {
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.05) {
                    self?.startFileWatcher(for: url, onChange: onChange)
                    onChange()
                }
            } else {
                onChange()
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
    }
}
