import Foundation
import AppKit

public struct InstalledApp: Identifiable, Hashable {
    public let id: String // bundleId
    public let name: String
    public let path: String
    public let bundleId: String

    public init(name: String, path: String, bundleId: String) {
        self.id = bundleId
        self.name = name
        self.path = path
        self.bundleId = bundleId
    }
}

public final class AppScanner: @unchecked Sendable {
    public static let shared = AppScanner()

    private let cache = NSCache<NSString, NSString>()

    public init() {}

    /// Scans standard macOS application directories for installed apps.
    public func scanInstalledApps() -> [InstalledApp] {
        let searchDirectories = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities"
        ]

        var apps: [InstalledApp] = []
        var seenBundleIds = Set<String>()

        let fileManager = FileManager.default

        for dir in searchDirectories {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: dir) else {
                continue
            }

            for item in contents where item.hasSuffix(".app") {
                let fullPath = (dir as NSString).appendingPathComponent(item)
                guard let bundle = Bundle(path: fullPath),
                      let bundleId = bundle.bundleIdentifier else {
                    continue
                }

                if seenBundleIds.contains(bundleId) {
                    continue
                }
                seenBundleIds.insert(bundleId)

                let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? (item as NSString).deletingPathExtension

                apps.append(InstalledApp(name: name, path: fullPath, bundleId: bundleId))
            }
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Extracts the app icon as a base64 encoded PNG string.
    public func getAppIconBase64(bundleId: String, maxDimension: CGFloat = 128) -> String? {
        if let cached = cache.object(forKey: bundleId as NSString) {
            return cached as String
        }

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }

        let icon = NSWorkspace.shared.icon(forFile: appURL.path)
        var proposedRect = NSRect(x: 0, y: 0, width: maxDimension, height: maxDimension)
        guard let cgImage = icon.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = NSSize(width: maxDimension, height: maxDimension)

        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }

        let base64 = pngData.base64EncodedString()
        cache.setObject(base64 as NSString, forKey: bundleId as NSString)
        return base64
    }

    /// Finds application URL by bundle identifier.
    public func url(forBundleId bundleId: String) -> URL? {
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)
    }
}
