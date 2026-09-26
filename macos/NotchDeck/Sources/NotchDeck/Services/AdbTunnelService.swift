import Foundation

/// Automatic ADB USB Reverse Tunnel Service for NotchDeck.
/// Detects connected Android devices via ADB and automatically applies
/// reverse port forwarding for the WebSocket server (8765) and APK portal (8080).
/// Eliminates the need for running terminal scripts when using USB connection.
public final class AdbTunnelService: @unchecked Sendable {
    public static let shared = AdbTunnelService()

    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.notchdeck.adbtunnel", qos: .utility)
    private var lastTunnelsEstablished: Bool = false
    private var cachedAdbPath: String?

    public init() {}

    public func start() {
        stop()
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + 1.0, repeating: 5.0)
        t.setEventHandler { [weak self] in
            self?.checkAndSetupTunnels()
        }
        t.resume()
        timer = t
    }

    public func stop() {
        timer?.cancel()
        timer = nil
    }

    /// Finds the `adb` executable on the system.
    public func locateAdb() -> String? {
        if let cached = cachedAdbPath, FileManager.default.isExecutableFile(atPath: cached) {
            return cached
        }

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let envHome = ProcessInfo.processInfo.environment["ANDROID_HOME"] ?? ""

        let candidates = [
            "/opt/homebrew/bin/adb",
            "/usr/local/bin/adb",
            "\(home)/Library/Android/sdk/platform-tools/adb",
            "\(envHome)/platform-tools/adb",
            "/usr/bin/adb"
        ]

        for path in candidates where !path.isEmpty {
            if FileManager.default.isExecutableFile(atPath: path) {
                cachedAdbPath = path
                return path
            }
        }

        // Try `which adb`
        let whichProcess = Process()
        let pipe = Pipe()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = ["adb"]
        whichProcess.standardOutput = pipe
        whichProcess.standardError = Pipe()

        do {
            try whichProcess.run()
            whichProcess.waitUntilExit()
            if whichProcess.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let found = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !found.isEmpty, FileManager.default.isExecutableFile(atPath: found) {
                    cachedAdbPath = found
                    return found
                }
            }
        } catch {}

        return nil
    }

    /// Executes `adb devices` to check for attached, authorized devices.
    private func hasConnectedDevice(adbPath: String) -> Bool {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: adbPath)
        process.arguments = ["devices"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return false }
            let lines = output.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !trimmed.hasPrefix("List of devices") && trimmed.hasSuffix("device") {
                    return true
                }
            }
        } catch {}
        return false
    }

    /// Run `adb reverse tcp:PORT tcp:PORT`
    private func reversePort(adbPath: String, port: UInt16) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: adbPath)
        process.arguments = ["reverse", "tcp:\(port)", "tcp:\(port)"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    public func checkAndSetupTunnels() {
        guard let adb = locateAdb() else { return }
        let hasDevice = hasConnectedDevice(adbPath: adb)

        if hasDevice {
            let wsSuccess = reversePort(adbPath: adb, port: 8765)
            let portalSuccess = reversePort(adbPath: adb, port: 8080)
            if wsSuccess || portalSuccess {
                if !lastTunnelsEstablished {
                    print("⚡ [NotchDeck] USB ADB reverse tunnel active: ports 8765 & 8080 forwarded automatically.")
                    lastTunnelsEstablished = true
                }
            }
        } else {
            lastTunnelsEstablished = false
        }
    }
}
