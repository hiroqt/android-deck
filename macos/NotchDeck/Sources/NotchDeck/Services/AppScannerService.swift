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
                let icon = AppIconManager.shared.extractCleanIcon(from: fullPath, pointSize: 32.0)
                results.append(InstalledAppInfo(name: name, bundleIdentifier: bundleId, path: fullPath, icon: icon))
            }
        }
        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

public final class AppIconManager {
    public static let shared = AppIconManager()
    private var cache = [String: NSImage]()
    private let queue = DispatchQueue(label: "com.notchdeck.appiconcache", attributes: .concurrent)

    public init() {}

    public func icon(for bundleId: String, name: String) -> NSImage? {
        let key = "\(bundleId.lowercased()):\(name.lowercased())"
        var cached: NSImage?
        queue.sync {
            cached = cache[key]
        }
        if let image = cached {
            return image
        }

        guard let appURL = findApplicationURL(bundleId: bundleId, name: name) else {
            return nil
        }

        let cleanIcon = extractCleanIcon(from: appURL.path, pointSize: 32.0)
        queue.async(flags: .barrier) {
            self.cache[key] = cleanIcon
        }
        return cleanIcon
    }

    public func findApplicationURL(bundleId: String, name: String) -> URL? {
        if !bundleId.isEmpty && bundleId != "empty",
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return url
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        let searchDirectories = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSHomeDirectory() + "/Applications"
        ]

        let targetLower = trimmedName.lowercased()
        for dir in searchDirectories {
            guard let items = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for item in items where item.hasSuffix(".app") {
                let fullPath = (dir as NSString).appendingPathComponent(item)
                let itemBase = (item as NSString).deletingPathExtension.lowercased()
                if itemBase == targetLower {
                    return URL(fileURLWithPath: fullPath)
                }
                if let bundle = Bundle(path: fullPath) {
                    let bDisplayName = bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    let bName = bundle.infoDictionary?["CFBundleName"] as? String
                    if bDisplayName?.lowercased() == targetLower || bName?.lowercased() == targetLower {
                        return URL(fileURLWithPath: fullPath)
                    }
                }
            }
        }

        return nil
    }

    public func extractCleanIcon(from path: String, pointSize: CGFloat = 32.0) -> NSImage {
        let rawIcon = NSWorkspace.shared.icon(forFile: path)
        let reps = rawIcon.representations.sorted {
            ($0.pixelsWide * $0.pixelsHigh) > ($1.pixelsWide * $1.pixelsHigh)
        }
        // Exclude low-res <= 32px representations which in some apps contain corrupted/garbled bitmaps
        let sourceRep = reps.first(where: { $0.pixelsWide >= 128 && $0.pixelsHigh >= 128 }) ?? reps.first
        guard let bestRep = sourceRep else {
            rawIcon.size = NSSize(width: pointSize, height: pointSize)
            return rawIcon
        }
        let targetSize = NSSize(width: pointSize, height: pointSize)
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        bestRep.draw(in: NSRect(origin: .zero, size: targetSize))
        newImage.unlockFocus()
        return newImage
    }
}
