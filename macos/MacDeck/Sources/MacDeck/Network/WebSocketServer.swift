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
        session.start()

        // Send hello.ack and initial profile snapshot to freshly connected client
        sendInitialProfile(to: session)
    }

    private func removeSession(_ session: ClientSession) {
        lock.lock()
        sessions.removeValue(forKey: session.id)
        let count = sessions.count
        lock.unlock()
        print("🔌 [MacDeck] Client disconnected. Total clients: \(count)")
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
            let ack = Envelope(
                type: "hello.ack",
                requestId: raw.requestId,
                payload: HelloAckPayload()
            )
            if let ackData = try? JSONEncoder().encode(ack) {
                session.send(data: ackData)
            }
            sendInitialProfile(to: session)

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
