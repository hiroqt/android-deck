import Foundation

public struct Envelope<T: Codable>: Codable {
    public let protocolVersion: Int
    public let type: String
    public let requestId: String
    public let timestamp: Int64
    public let payload: T

    public init(protocolVersion: Int = 1, type: String, requestId: String = UUID().uuidString, timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000), payload: T) {
        self.protocolVersion = protocolVersion
        self.type = type
        self.requestId = requestId
        self.timestamp = timestamp
        self.payload = payload
    }
}

public struct RawEnvelope: Codable {
    public let protocolVersion: Int
    public let type: String
    public let requestId: String
    public let timestamp: Int64
    public let payload: [String: AnyCodableValue]?

    public init(protocolVersion: Int = 1, type: String, requestId: String = UUID().uuidString, timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000), payload: [String: AnyCodableValue]? = nil) {
        self.protocolVersion = protocolVersion
        self.type = type
        self.requestId = requestId
        self.timestamp = timestamp
        self.payload = payload
    }
}

public enum AnyCodableValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported AnyCodableValue type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - Payloads

public struct HelloPayload: Codable {
    public let clientName: String?
    public let platform: String?
    public let appVersion: String?
    public let batteryLevel: Int?
    public let isCharging: Bool?

    public init(clientName: String? = nil, platform: String? = nil, appVersion: String? = nil, batteryLevel: Int? = nil, isCharging: Bool? = nil) {
        self.clientName = clientName
        self.platform = platform
        self.appVersion = appVersion
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
    }
}

public struct DeviceBatteryPayload: Codable, Equatable {
    public let level: Int
    public let isCharging: Bool
    public let plugged: String?

    public init(level: Int, isCharging: Bool, plugged: String? = nil) {
        self.level = level
        self.isCharging = isCharging
        self.plugged = plugged
    }
}

public struct HelloAckPayload: Codable {
    public let serverName: String
    public let osVersion: String
    public let appVersion: String

    public init(serverName: String = "MacDeck Host", osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString, appVersion: String = "1.0.0") {
        self.serverName = serverName
        self.osVersion = osVersion
        self.appVersion = appVersion
    }
}

public struct DeckControl: Codable, Identifiable {
    public let id: String
    public let label: String
    public let bundleId: String
    public let iconPngBase64: String?

    public init(id: String, label: String, bundleId: String, iconPngBase64: String? = nil) {
        self.id = id
        self.label = label
        self.bundleId = bundleId
        self.iconPngBase64 = iconPngBase64
    }
}

public struct ProfileSnapshotPayload: Codable {
    public let id: String
    public let name: String
    public let revision: Int
    public let maxColumns: Int
    public let maxRows: Int
    public let controls: [DeckControl]

    public init(id: String = "main-deck", name: String = "My Apps", revision: Int = 1, maxColumns: Int = 3, maxRows: Int = 3, controls: [DeckControl]) {
        self.id = id
        self.name = name
        self.revision = revision
        self.maxColumns = maxColumns
        self.maxRows = maxRows
        self.controls = controls
    }
}

public struct ActionInvokePayload: Codable {
    public let controlId: String
    public let event: String

    public init(controlId: String, event: String = "tap") {
        self.controlId = controlId
        self.event = event
    }
}

public struct ActionResultPayload: Codable {
    public let controlId: String
    public let status: String // "OK" or "ERROR"
    public let errorCode: String?
    public let errorMessage: String?

    public init(controlId: String, status: String, errorCode: String? = nil, errorMessage: String? = nil) {
        self.controlId = controlId
        self.status = status
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }

    public static func ok(controlId: String) -> ActionResultPayload {
        return ActionResultPayload(controlId: controlId, status: "OK")
    }

    public static func error(controlId: String, code: String, message: String) -> ActionResultPayload {
        return ActionResultPayload(controlId: controlId, status: "ERROR", errorCode: code, errorMessage: message)
    }
}

public struct EmptyPayload: Codable {}
