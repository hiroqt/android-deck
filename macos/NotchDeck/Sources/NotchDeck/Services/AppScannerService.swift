import AppKit

public struct InstalledAppInfo: Identifiable, Equatable {
    public var id: String { bundleIdentifier }
    public let name: String
    public let bundleIdentifier: String
    public let path: String
    public let icon: NSImage?

    public init(name: String, bundleIdentifier: String, path: String, icon: NSImage? = nil) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.icon = icon
    }
}

public final class AppScannerService {
    public static let shared = AppScannerService()

    public init() {}

    public func scanInstalledApps() -> [InstalledAppInfo] {
        let searchDirectories = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSHomeDirectory() + "/Applications"
        ]

        var results: [InstalledAppInfo] = []
        var seenBundleIds = Set<String>()

        for dir in searchDirectories {
            guard let items = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for item in items where item.hasSuffix(".app") {
                let fullPath = (dir as NSString).appendingPathComponent(item)
                guard let bundle = Bundle(path: fullPath),
                      let bundleId = bundle.bundleIdentifier else { continue }
                if seenBundleIds.contains(bundleId) { continue }
                seenBundleIds.insert(bundleId)

                let name = bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? bundle.infoDictionary?["CFBundleName"] as? String
                    ?? (item as NSString).deletingPathExtension
                let icon = NSWorkspace.shared.icon(forFile: fullPath)
                results.append(InstalledAppInfo(name: name, bundleIdentifier: bundleId, path: fullPath, icon: icon))
            }
        }
        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
