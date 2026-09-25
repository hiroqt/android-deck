import Foundation

public protocol ConfigManagerProtocol: AnyObject {
    var config: NotchDeckConfig { get }
    func loadConfig() -> NotchDeckConfig
    func saveConfig(_ newConfig: NotchDeckConfig) throws
    func updateSlot(_ slot: DeckSlot)
    func resetToDefault()
}

public final class ConfigManager: ObservableObject, ConfigManagerProtocol {
    public static let shared = ConfigManager()

    private let fileURL: URL
    @Published public private(set) var config: NotchDeckConfig

    public init(fileURL: URL? = nil) {
        if let fileURL = fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent("NotchDeck", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent("config.json")
        }
        self.config = NotchDeckConfig.defaultConfig()
        self.config = loadConfig()
    }

    public func loadConfig() -> NotchDeckConfig {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let fallback = NotchDeckConfig.defaultConfig()
            try? saveConfig(fallback)
            return fallback
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let loaded = try JSONDecoder().decode(NotchDeckConfig.self, from: data)
            if Thread.isMainThread {
                self.config = loaded
            } else {
                DispatchQueue.main.async { self.config = loaded }
            }
            return loaded
        } catch {
            let fallback = NotchDeckConfig.defaultConfig()
            try? saveConfig(fallback)
            return fallback
        }
    }

    public func saveConfig(_ newConfig: NotchDeckConfig) throws {
        let parentDir = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(newConfig)
        try data.write(to: fileURL, options: .atomic)
        if Thread.isMainThread {
            self.config = newConfig
        } else {
            DispatchQueue.main.async {
                self.config = newConfig
            }
        }
    }

    public func updateSlot(_ slot: DeckSlot) {
        var current = config
        if let idx = current.slots.firstIndex(where: { $0.id == slot.id || $0.index == slot.index }) {
            current.slots[idx] = slot
            try? saveConfig(current)
        }
    }

    public func resetToDefault() {
        let defaultConfig = NotchDeckConfig.defaultConfig()
        try? saveConfig(defaultConfig)
    }
}
