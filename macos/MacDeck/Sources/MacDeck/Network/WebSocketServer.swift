import Foundation
import Network

public final class WebSocketServer: @unchecked Sendable {
    public static let shared = WebSocketServer()

    public let port: UInt16
    private var listener: NWListener?
    private var sessions: [UUID: ClientSession] = [:]
    private let lock = NSLock()

    private let profileManager: ProfileManager
    private let actionRegistry: ActionRegistry

    public init(port: UInt16 = 8765, profileManager: ProfileManager = .shared, actionRegistry: ActionRegistry = .shared) {
        self.port = port
        self.profileManager = profileManager
        self.actionRegistry = actionRegistry

        // Wire profile changed listener to broadcast
        self.profileManager.onProfileChanged = { [weak self] snapshot in
            self?.broadcastProfile(snapshot: snapshot)
        }
    }

    public func start() throws {
        let parameters = NWParameters.tcp
        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw NSError(domain: "MacDeck", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid port \(port)"])
        }

        let listener = try NWListener(using: parameters, on: nwPort)
        self.listener = listener

        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("🚀 [MacDeck] Server listening on port \(nwPort.rawValue)")
            case .failed(let error):
                print("❌ [MacDeck] Server failed: \(error)")
            case .cancelled:
                print("⏹️ [MacDeck] Server cancelled")
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }

        listener.start(queue: .global(qos: .userInitiated))
    }

    private func handleNewConnection(_ connection: NWConnection) {
        let session = ClientSession(
            connection: connection,
            onMessage: { [weak self] data, session in
                self?.handleIncomingMessage(data, from: session)
            },
            onClose: { [weak self] session in
                self?.removeSession(session)
            }
        )

        lock.lock()
        sessions[session.id] = session
        let count = sessions.count
        lock.unlock()

        print("📱 [MacDeck] New client connected. Total clients: \(count)")
        updateStatusFile(connected: true, clientName: "Android Device", clientCount: count)
        session.start()

        // Send hello.ack and initial profile snapshot to freshly connected client
        sendInitialProfile(to: session)
    }

    private var currentClientName: String?
    private var currentBatteryLevel: Int?
    private var currentIsCharging: Bool = false

    private func removeSession(_ session: ClientSession) {
        lock.lock()
        sessions.removeValue(forKey: session.id)
        let count = sessions.count
        lock.unlock()
        print("🔌 [MacDeck] Client disconnected. Total clients: \(count)")
        updateStatusFile(connected: count > 0, clientName: count > 0 ? currentClientName : nil, clientCount: count)
    }

    private func updateStatusFile(
        connected: Bool,
        clientName: String? = nil,
        clientCount: Int? = nil,
        batteryLevel: Int? = nil,
        isCharging: Bool? = nil
    ) {
        if let clientName = clientName { self.currentClientName = clientName }
        if let batteryLevel = batteryLevel { self.currentBatteryLevel = batteryLevel }
        if let isCharging = isCharging { self.currentIsCharging = isCharging }
        if !connected {
            self.currentClientName = nil
            self.currentBatteryLevel = nil
            self.currentIsCharging = false
        }

        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".macdeck", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let statusURL = dir.appendingPathComponent("status.json")
        var statusObj: [String: Any] = [
            "connected": connected,
            "clientCount": clientCount ?? sessions.count,
            "port": port,
            "timestamp": Date().timeIntervalSince1970
        ]
        if let name = self.currentClientName {
            statusObj["clientName"] = name
        }
        if let batt = self.currentBatteryLevel {
            statusObj["batteryLevel"] = batt
            statusObj["isCharging"] = self.currentIsCharging
        }
        if let data = try? JSONSerialization.data(withJSONObject: statusObj, options: [.prettyPrinted]) {
            try? data.write(to: statusURL, options: .atomic)
        }
    }

    private func sendInitialProfile(to session: ClientSession) {
        let snapshot = profileManager.getCurrentProfileSnapshot()
        let envelope = Envelope(
            type: "profile.snapshot",
            payload: snapshot
        )
        if let data = try? JSONEncoder().encode(envelope) {
            session.send(data: data)
        }
    }

    public func broadcastProfile(snapshot: ProfileSnapshotPayload) {
        let envelope = Envelope(
            type: "profile.changed",
            payload: snapshot
        )
        guard let data = try? JSONEncoder().encode(envelope) else { return }

        lock.lock()
        let currentSessions = Array(sessions.values)
        lock.unlock()

        print("📡 [MacDeck] Broadcasting profile update to \(currentSessions.count) clients")
        for session in currentSessions {
            session.send(data: data)
        }
    }

    private func handleIncomingMessage(_ data: Data, from session: ClientSession) {
        guard let raw = try? JSONDecoder().decode(RawEnvelope.self, from: data) else {
            print("⚠️ [MacDeck] Failed to decode raw envelope")
            return
        }

        print("📩 [MacDeck] Received message type: '\(raw.type)' [requestId: \(raw.requestId)]")

        switch raw.type {
        case "hello":
            var clientName = "Android Device"
            var batteryLevel: Int? = nil
            var isCharging: Bool? = nil
            if let helloEnv = try? JSONDecoder().decode(Envelope<HelloPayload>.self, from: data) {
                if let name = helloEnv.payload.clientName, !name.isEmpty {
                    clientName = name
                }
                batteryLevel = helloEnv.payload.batteryLevel
                isCharging = helloEnv.payload.isCharging
            }
            lock.lock()
            let count = sessions.count
            lock.unlock()
            updateStatusFile(connected: true, clientName: clientName, clientCount: count, batteryLevel: batteryLevel, isCharging: isCharging)

            let ack = Envelope(
                type: "hello.ack",
                requestId: raw.requestId,
                payload: HelloAckPayload()
            )
            if let ackData = try? JSONEncoder().encode(ack) {
                session.send(data: ackData)
            }
            sendInitialProfile(to: session)

        case "device.battery":
            if let battEnv = try? JSONDecoder().decode(Envelope<DeviceBatteryPayload>.self, from: data) {
                print("🔋 [MacDeck] Battery update: \(battEnv.payload.level)% (charging: \(battEnv.payload.isCharging))")
                lock.lock()
                let count = sessions.count
                lock.unlock()
                updateStatusFile(connected: count > 0, clientCount: count, batteryLevel: battEnv.payload.level, isCharging: battEnv.payload.isCharging)
            }

        case "profile.get", "profile.refresh":
            print("🔄 [MacDeck] Received \(raw.type) request [requestId: \(raw.requestId)]")
            profileManager.reloadFromDisk()
            let snapshot = profileManager.getCurrentProfileSnapshot()
            let envelope = Envelope(
                type: "profile.snapshot",
                requestId: raw.requestId,
                payload: snapshot
            )
            if let snapData = try? JSONEncoder().encode(envelope) {
                session.send(data: snapData)
            }

        case "ping":
            let pong = Envelope(
                type: "pong",
                requestId: raw.requestId,
                payload: EmptyPayload()
            )
            if let pongData = try? JSONEncoder().encode(pong) {
                session.send(data: pongData)
            }

        case "action.invoke":
            guard let invokeEnv = try? JSONDecoder().decode(Envelope<ActionInvokePayload>.self, from: data) else {
                let errResult = ActionResultPayload.error(
                    controlId: "unknown",
                    code: "INVALID_PAYLOAD",
                    message: "Malformed action.invoke payload"
                )
                let resEnv = Envelope(type: "action.result", requestId: raw.requestId, payload: errResult)
                if let errData = try? JSONEncoder().encode(resEnv) {
                    session.send(data: errData)
                }
                return
            }

            Task {
                let result = await actionRegistry.invoke(
                    controlId: invokeEnv.payload.controlId,
                    event: invokeEnv.payload.event
                )
                let resEnv = Envelope(
                    type: "action.result",
                    requestId: invokeEnv.requestId,
                    payload: result
                )
                if let resData = try? JSONEncoder().encode(resEnv) {
                    session.send(data: resData)
                }
            }

        default:
            print("⚠️ [MacDeck] Unhandled message type: \(raw.type)")
        }
    }

    public func stop() {
        listener?.cancel()
        lock.lock()
        for session in sessions.values {
            session.close()
        }
        sessions.removeAll()
        lock.unlock()
    }
}
