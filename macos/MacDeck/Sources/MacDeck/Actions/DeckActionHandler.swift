import Foundation

public enum DeckActionError: Error, LocalizedError {
    case actionUnknown(String)
    case appNotFound(String)
    case launchFailed(String)
    case invalidPayload(String)
    case internalError(String)

    public var errorCode: String {
        switch self {
        case .actionUnknown: return "ACTION_UNKNOWN"
        case .appNotFound: return "APP_NOT_FOUND"
        case .launchFailed: return "LAUNCH_FAILED"
        case .invalidPayload: return "INVALID_PAYLOAD"
        case .internalError: return "INTERNAL_ERROR"
        }
    }

    public var errorDescription: String? {
        switch self {
        case .actionUnknown(let id): return "Unknown action: \(id)"
        case .appNotFound(let id): return "Application not found: \(id)"
        case .launchFailed(let msg): return "Launch failed: \(msg)"
        case .invalidPayload(let msg): return "Invalid payload: \(msg)"
        case .internalError(let msg): return "Internal error: \(msg)"
        }
    }
}

public protocol DeckActionHandler: Sendable {
    var actionType: String { get }
    func execute(controlId: String, parameters: [String: String]) async throws -> ActionResultPayload
}
