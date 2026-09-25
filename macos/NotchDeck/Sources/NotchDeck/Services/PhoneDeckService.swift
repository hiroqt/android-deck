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

    public init(connected: Bool = false, clientName: String? = nil, clientCount: Int = 0, port: UInt16 = 8765, timestamp: Double = Date().timeIntervalSince1970) {
        self.connected = connected
        self.clientName = clientName
        self.clientCount = clientCount
        self.port = port
        self.timestamp = timestamp
    }
}

public final class PhoneDeckService: ObservableObject {
    public static let shared = PhoneDeckService()

    private let profileURL: URL
    private let statusURL: URL

    @Published public private(set) var slots: [PhoneDeckSlot] = []
    @Published public private(set) var isDeviceConnected: Bool = false
    @Published public private(set) var connectedDeviceName: String? = nil
    @Published public private(set) var clientCount: Int = 0

    private var profileWatcher: DispatchSourceFileSystemObject?
    private var statusWatcher: DispatchSourceFileSystemObject?
    private var pollTimer: Timer?

    public init(baseDirectory: URL? = nil) {
        let dir: URL
        if let baseDirectory = baseDirectory {
            dir = baseDirectory
        } else {
            let home = FileManager.default.homeDirectoryForCurrentUser
            dir = home.appendingPathComponent(".macdeck", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.profileURL = dir.appendingPathComponent("profile.json")
        self.statusURL = dir.appendingPathComponent("status.json")

        loadProfile()
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
            }
            return
        }

        DispatchQueue.main.async {
            self.isDeviceConnected = status.connected && status.clientCount > 0
            self.connectedDeviceName = status.clientName
            self.clientCount = status.clientCount
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
