import Foundation

public final class ActionRegistry: @unchecked Sendable {
    public static let shared = ActionRegistry()

    private var handlers: [String: DeckActionHandler] = [:]
    private let profileManager: ProfileManager
    private let lock = NSLock()

    public init(profileManager: ProfileManager = .shared) {
        self.profileManager = profileManager
        register(LaunchAppAction())
    }

    public func register(_ handler: DeckActionHandler) {
        lock.lock()
        defer { lock.unlock() }
        handlers[handler.actionType] = handler
    }

    public func invoke(controlId: String, event: String) async -> ActionResultPayload {
        guard let bundleId = profileManager.getBundleId(for: controlId) else {
            return ActionResultPayload.error(
                controlId: controlId,
                code: "ACTION_UNKNOWN",
                message: "No action registered for control ID: \(controlId)"
            )
        }

        lock.lock()
        let handler = handlers["launch_app"]
        lock.unlock()

        guard let handler = handler else {
            return ActionResultPayload.error(
                controlId: controlId,
                code: "INTERNAL_ERROR",
                message: "LaunchAppAction handler not registered"
            )
        }

        do {
            return try await handler.execute(controlId: controlId, parameters: ["bundleId": bundleId])
        } catch let err as DeckActionError {
            return ActionResultPayload.error(
                controlId: controlId,
                code: err.errorCode,
                message: err.errorDescription ?? err.localizedDescription
            )
        } catch {
            return ActionResultPayload.error(
                controlId: controlId,
                code: "INTERNAL_ERROR",
                message: error.localizedDescription
            )
        }
    }
}
