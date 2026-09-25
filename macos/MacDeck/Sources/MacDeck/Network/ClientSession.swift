import Foundation
import Network

public final class ClientSession: @unchecked Sendable {
    public let id = UUID()
    public let connection: NWConnection
    private let onMessage: @Sendable (Data, ClientSession) -> Void
    private let onClose: @Sendable (ClientSession) -> Void

    public init(
        connection: NWConnection,
        onMessage: @escaping @Sendable (Data, ClientSession) -> Void,
        onClose: @escaping @Sendable (ClientSession) -> Void
    ) {
        self.connection = connection
        self.onMessage = onMessage
        self.onClose = onClose
    }

    public func start() {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.receiveNextMessage()
            case .failed, .cancelled:
                self.onClose(self)
            default:
                break
            }
        }
        connection.start(queue: .global(qos: .userInitiated))
    }

    private func receiveNextMessage() {
        connection.receiveMessage { [weak self] content, context, isComplete, error in
            guard let self = self else { return }
            if let error = error {
                print("⚠️ [MacDeck] Client session error: \(error)")
                self.onClose(self)
                return
            }

            if let data = content, !data.isEmpty {
                self.onMessage(data, self)
            }

            if self.connection.state == .ready {
                self.receiveNextMessage()
            }
        }
    }

    public func send(data: Data) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "textContext", metadata: [metadata])
        connection.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
    }

    public func close() {
        connection.cancel()
    }
}
