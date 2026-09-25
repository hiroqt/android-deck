import Foundation
import AppKit

public final class ActionExecutionService {
    public static let shared = ActionExecutionService()

    private let appScanner: AppScannerService
    private let systemControl: SystemControlService
    private let mediaControl: MediaControlService

    public init(
        appScanner: AppScannerService = .shared,
        systemControl: SystemControlService = .shared,
        mediaControl: MediaControlService = .shared
    ) {
        self.appScanner = appScanner
        self.systemControl = systemControl
        self.mediaControl = mediaControl
    }

    @discardableResult
    public func execute(slot: DeckSlot) -> Bool {
        switch slot.actionType {
        case .appLauncher:
            return launchApp(bundleId: slot.target)
        case .mediaControl:
            return handleMedia(command: slot.target)
        case .systemToggle:
            return handleSystemToggle(toggle: slot.target)
        case .shellScript:
            return executeShell(command: slot.target)
        case .urlBookmark:
            return openURL(urlString: slot.target)
        }
    }

    private func launchApp(bundleId: String) -> Bool {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
            return true
        }
        return false
    }

    private func handleMedia(command: String) -> Bool {
        switch command {
        case "playPause":
            mediaControl.playPause()
            return true
        case "nextTrack":
            mediaControl.nextTrack()
            return true
        case "previousTrack":
            mediaControl.previousTrack()
            return true
        default:
            return false
        }
    }

    private func handleSystemToggle(toggle: String) -> Bool {
        switch toggle {
        case "micMute":
            systemControl.toggleMicMute()
            return true
        case "volumeMute":
            systemControl.toggleVolumeMute()
            return true
        case "screenshot":
            systemControl.captureInteractiveScreenshot()
            return true
        case "lockScreen":
            systemControl.lockScreen()
            return true
        default:
            return false
        }
    }

    private func executeShell(command: String) -> Bool {
        guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        do {
            try process.run()
            return true
        } catch {
            return false
        }
    }

    private func openURL(urlString: String) -> Bool {
        guard let url = URL(string: urlString), NSWorkspace.shared.open(url) else { return false }
        return true
    }
}
