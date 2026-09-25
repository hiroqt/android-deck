import Foundation

public final class ActionRegistry: @unchecked Sendable {
    public static let shared = ActionRegistry()

    private var handlers: [String: DeckActionHandler] = [:]
    private let profileManager: ProfileManager
    private let lock = NSLock()

    public init(profileManager: ProfileManager = .shared) {
        self.profileManager = profileManager
        register(LaunchAppAction())
        register(SystemControlAction())
    }

    public func register(_ handler: DeckActionHandler) {
        lock.lock()
        defer { lock.unlock() }
        handlers[handler.actionType] = handler
    }

    private func handler(for actionType: String) -> DeckActionHandler? {
        lock.lock()
        defer { lock.unlock() }
        return handlers[actionType]
    }

    public func invoke(controlId: String, event: String) async -> ActionResultPayload {
        if controlId.hasPrefix("sys_") {
            guard let handler = handler(for: "system_control") else {
                return ActionResultPayload.error(
                    controlId: controlId,
                    code: "INTERNAL_ERROR",
                    message: "SystemControlAction handler not registered"
                )
            }

            do {
                return try await handler.execute(controlId: controlId, parameters: ["event": event])
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

        guard let bundleId = profileManager.getBundleId(for: controlId) else {
            return ActionResultPayload.error(
                controlId: controlId,
                code: "ACTION_UNKNOWN",
                message: "No action registered for control ID: \(controlId)"
            )
        }

        guard let handler = handler(for: "launch_app") else {
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
