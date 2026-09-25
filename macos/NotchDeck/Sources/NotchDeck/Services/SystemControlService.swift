import Foundation
import AppKit

public final class SystemControlService {
    public static let shared = SystemControlService()

    public init() {}

    public func isMicMuted() -> Bool {
        let script = "input volume of (get volume settings)"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let output = appleScript.executeAndReturnError(&error)
            return output.int32Value == 0
        }
        return false
    }

    @discardableResult
    public func toggleMicMute() -> Bool {
        let script = """
        set curVol to input volume of (get volume settings)
        if curVol is 0 then
            set volume input volume 75
            return false
        else
            set volume input volume 0
            return true
        end if
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let output = appleScript.executeAndReturnError(&error)
            return output.booleanValue
        }
        return false
    }

    public func toggleVolumeMute() {
        let script = "set volume output muted not (output muted of (get volume settings))"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    public func captureInteractiveScreenshot() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-c"] // Interactive capture to clipboard
        try? process.run()
    }

    public func lockScreen() {
        let script = """
        tell application "System Events" to sleep
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
