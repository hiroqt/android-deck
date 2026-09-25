import Foundation
import AppKit

public struct LaunchAppAction: DeckActionHandler {
    public let actionType = "launch_app"

    public init() {}

    public func execute(controlId: String, parameters: [String: String]) async throws -> ActionResultPayload {
        guard let bundleId = parameters["bundleId"], !bundleId.isEmpty else {
            throw DeckActionError.invalidPayload("Missing bundleId parameter")
        }

        // Handle special system apps like Finder
        if bundleId == "com.apple.finder" {
            let success = await MainActor.run {
                NSWorkspace.shared.launchApplication("Finder")
            }
            if success {
                return ActionResultPayload.ok(controlId: controlId)
            }
        }

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            throw DeckActionError.appNotFound(bundleId)
        }

        do {
            let config = NSWorkspace.OpenConfiguration()
            config.promptsUserIfNeeded = false
            config.activates = true

            _ = try await NSWorkspace.shared.openApplication(at: appURL, configuration: config)
            return ActionResultPayload.ok(controlId: controlId)
        } catch {
            throw DeckActionError.launchFailed(error.localizedDescription)
        }
    }
}
