import Foundation
import Network
import AppKit

public final class PhoneDeckHostServer: @unchecked Sendable {
    public static let shared = PhoneDeckHostServer()

    public let port: UInt16 = 8765
    public let udpPort: UInt16 = 8766

    private var tcpListener: NWListener?
    private var udpListener: NWListener?
    private var udpBeaconTimer: DispatchSourceTimer?
    private var sessions: [UUID: NWConnection] = [:]
    private let lock = NSLock()
    private var iconCache = NSCache<NSString, NSString>()

    public private(set) var isRunning: Bool = false

    public var activeClientCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return sessions.count
    }

    public var hasActiveClients: Bool {
        return activeClientCount > 0
    }

    public init() {}

    // MARK: - Lifecycle

    public func start() {
        guard !isRunning else { return }
        startTcpServer()
        startUdpDiscoveryResponder()
        startUdpBeacon()
        isRunning = true
    }

    public func stop() {
        guard isRunning else { return }
        udpBeaconTimer?.cancel()
        udpBeaconTimer = nil

        udpListener?.cancel()
        udpListener = nil

        tcpListener?.cancel()
        tcpListener = nil

        lock.lock()
        for (_, conn) in sessions {
            conn.cancel()
        }
        sessions.removeAll()
        lock.unlock()

        isRunning = false
    }

    // MARK: - TCP WebSocket Server (Port 8765)

    private func startTcpServer() {
        let parameters = NWParameters.tcp
        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)

        guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }

        do {
            let listener = try NWListener(using: parameters, on: nwPort)
            self.tcpListener = listener

            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("🚀 [NotchDeck] Embedded WebSocket Host listening on port \(nwPort.rawValue)")
                case .failed(let error):
                    print("⚠️ [NotchDeck] WebSocket Host port \(nwPort.rawValue) unavailable: \(error)")
                default:
                    break
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }

            listener.start(queue: .global(qos: .userInitiated))
        } catch {
            print("⚠️ [NotchDeck] Could not start WebSocket server on port \(port): \(error)")
        }
    }

    private func handleNewConnection(_ connection: NWConnection) {
        let sessionId = UUID()
        lock.lock()
        sessions[sessionId] = connection
        let count = sessions.count
        lock.unlock()

        print("📱 [NotchDeck] Android device connected. Total clients: \(count)")

        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.receiveNextMessage(from: connection, sessionId: sessionId)
            case .failed, .cancelled:
                self.removeSession(sessionId)
            default:
                break
            }
        }

        connection.start(queue: .global(qos: .userInitiated))

        // Update PhoneDeckService status
        DispatchQueue.main.async {
            PhoneDeckService.shared.setDeviceConnected(true, name: "Android Phone", count: count)
        }

        // Send initial profile & system status
        sendProfileSnapshot(to: connection)
        sendSystemStatus(to: connection)
    }

    private func removeSession(_ sessionId: UUID) {
        lock.lock()
        sessions.removeValue(forKey: sessionId)
        let count = sessions.count
        lock.unlock()

        print("🔌 [NotchDeck] Android device disconnected. Remaining: \(count)")

        DispatchQueue.main.async {
            PhoneDeckService.shared.setDeviceConnected(count > 0, count: count)
        }
    }

    private func receiveNextMessage(from connection: NWConnection, sessionId: UUID) {
        connection.receiveMessage { [weak self] content, context, isComplete, error in
            guard let self = self else { return }
            if let error = error {
                print("⚠️ [NotchDeck] Connection error: \(error)")
                self.removeSession(sessionId)
                return
            }

            if let data = content, !data.isEmpty {
                self.handleIncomingData(data, connection: connection)
            }

            if connection.state == .ready {
                self.receiveNextMessage(from: connection, sessionId: sessionId)
            }
        }
    }

    private func handleIncomingData(_ data: Data, connection: NWConnection) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        let requestId = json["requestId"] as? String ?? UUID().uuidString

        switch type {
        case "hello":
            let payload = json["payload"] as? [String: Any] ?? [:]
            let clientName = (payload["clientName"] as? String) ?? (payload["name"] as? String) ?? "Android Device"
            let battery = (payload["batteryLevel"] as? Int) ?? (payload["level"] as? Int)
            let charging = (payload["isCharging"] as? Bool) ?? (payload["charging"] as? Bool) ?? false

            DispatchQueue.main.async {
                PhoneDeckService.shared.setDeviceConnected(true, name: clientName, count: self.sessions.count)
                if let battery = battery {
                    PhoneDeckService.shared.updateBattery(level: battery, charging: charging)
                }
            }

            // Send hello.ack, profile snapshot and system status
            let ack: [String: Any] = [
                "protocolVersion": 1,
                "type": "hello.ack",
                "requestId": requestId,
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "payload": [
                    "serverVersion": "1.0.0",
                    "hostName": Host.current().localizedName ?? "Mac"
                ]
            ]
            sendJson(ack, to: connection)
            sendProfileSnapshot(to: connection)
            sendSystemStatus(to: connection)

        case "device.battery":
            if let payload = json["payload"] as? [String: Any],
               let level = (payload["level"] as? Int) ?? (payload["batteryLevel"] as? Int) {
                let charging = (payload["isCharging"] as? Bool) ?? (payload["charging"] as? Bool) ?? false
                DispatchQueue.main.async {
                    PhoneDeckService.shared.updateBattery(level: level, charging: charging)
                }
            }

        case "action.invoke":
            if let payload = json["payload"] as? [String: Any],
               let controlId = payload["controlId"] as? String {
                let event = payload["event"] as? String ?? "tap"
                self.handleActionInvoke(controlId: controlId, event: event, requestId: requestId, connection: connection)
            }

        case "profile.request", "profile.refresh", "profile.get":
            PhoneDeckService.shared.loadProfile()
            sendProfileSnapshot(to: connection)
            sendSystemStatus(to: connection)

        case "system.status.request", "system.status":
            sendSystemStatus(to: connection)

        case "ping":
            let pong: [String: Any] = [
                "protocolVersion": 1,
                "type": "pong",
                "requestId": requestId,
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "payload": [:]
            ]
            sendJson(pong, to: connection)

        default:
            break
        }
    }

    private func handleActionInvoke(controlId: String, event: String, requestId: String, connection: NWConnection) {
        var success = false

        // System Control Actions (from ControlPanelView)
        if controlId == "sys_bluetooth" {
            SystemControlService.shared.setBluetooth(state: event)
            broadcastSystemStatus()
            success = true
        } else if controlId == "sys_wifi" {
            SystemControlService.shared.setWifi(state: event)
            broadcastSystemStatus()
            success = true
        } else if controlId == "sys_volume" {
            if event.hasPrefix("set:") {
                let levelStr = event.replacingOccurrences(of: "set:", with: "")
                if let level = Int(levelStr) {
                    SystemControlService.shared.setOutputVolume(level)
                    success = true
                }
            } else if event == "mute" {
                SystemControlService.shared.toggleVolumeMute()
                success = true
            }
            broadcastSystemStatus()
        } else if controlId == "sys_brightness" {
            if event.hasPrefix("set:") {
                let levelStr = event.replacingOccurrences(of: "set:", with: "")
                if let level = Float(levelStr) {
                    SystemControlService.shared.setBrightness(level / 100.0)
                    success = true
                }
            }
            broadcastSystemStatus()
        } else if controlId == "sys_audio_device" {
            let targetName = event.replacingOccurrences(of: "select:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            success = SystemControlService.shared.setDefaultAudioOutputDevice(name: targetName)
            broadcastSystemStatus()
        } else if controlId == "sys_mic_mute" {
            SystemControlService.shared.toggleMicMute()
            success = true
        } else if controlId == "sys_volume_mute" {
            SystemControlService.shared.toggleVolumeMute()
            broadcastSystemStatus()
            success = true
        } else if controlId == "sys_screenshot" {
            SystemControlService.shared.captureInteractiveScreenshot()
            success = true
        } else if controlId == "sys_lock" {
            SystemControlService.shared.lockScreen()
            success = true
        } else if controlId == "media_play_pause" {
            MediaControlService.shared.playPause()
            success = true
        } else if controlId == "media_next" {
            MediaControlService.shared.nextTrack()
            success = true
        } else if controlId == "media_prev" {
            MediaControlService.shared.previousTrack()
            success = true
        } else {
            // App launcher / Slot action
            let slots = PhoneDeckService.shared.slots
            var targetBundleId = ""

            if let matchingSlot = slots.first(where: { $0.id == controlId }), !matchingSlot.isEmpty {
                targetBundleId = matchingSlot.bundleId
            } else if controlId.hasPrefix("app-"),
                      let idx = Int(controlId.replacingOccurrences(of: "app-", with: "")),
                      idx > 0 && idx <= slots.count {
                let s = slots[idx - 1]
                if !s.isEmpty {
                    targetBundleId = s.bundleId
                }
            } else if controlId.contains(".") {
                targetBundleId = controlId
            }

            if !targetBundleId.isEmpty && targetBundleId != "empty" {
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: targetBundleId) {
                    let config = NSWorkspace.OpenConfiguration()
                    config.activates = true
                    NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
                    success = true
                }
            }
        }

        let result: [String: Any] = [
            "protocolVersion": 1,
            "type": "action.result",
            "requestId": requestId,
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "payload": [
                "status": success ? "OK" : "ERROR",
                "controlId": controlId
            ]
        ]
        sendJson(result, to: connection)
    }

    // MARK: - System Status Broadcasting

    public func buildSystemStatus() -> [String: Any] {
        let volume = SystemControlService.shared.getOutputVolume()
        let brightness = Int(round(SystemControlService.shared.getBrightness() * 100))
        let wifiOn = SystemControlService.shared.isWifiOn()
        let btOn = SystemControlService.shared.isBluetoothOn()
        let devices = SystemControlService.shared.getAudioOutputDevices()
        let defaultDevice = SystemControlService.shared.getDefaultAudioOutputDevice()

        return [
            "protocolVersion": 1,
            "type": "system.status",
            "requestId": UUID().uuidString,
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "payload": [
                "volume": volume,
                "brightness": brightness,
                "isWifiOn": wifiOn,
                "isBluetoothOn": btOn,
                "audioDevices": devices,
                "currentAudioDevice": defaultDevice
            ]
        ]
    }

    public func sendSystemStatus(to connection: NWConnection) {
        let status = buildSystemStatus()
        sendJson(status, to: connection)
    }

    public func broadcastSystemStatus() {
        let status = buildSystemStatus()
        guard let data = try? JSONSerialization.data(withJSONObject: status) else { return }

        lock.lock()
        let conns = Array(sessions.values)
        lock.unlock()

        for conn in conns {
            let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
            let context = NWConnection.ContentContext(identifier: "textContext", metadata: [metadata])
            conn.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
        }
    }

    // MARK: - Profile Broadcasting

    public func broadcastProfile() {
        let snapshot = buildProfileSnapshot()
        guard let data = try? JSONSerialization.data(withJSONObject: snapshot) else { return }

        lock.lock()
        let conns = Array(sessions.values)
        lock.unlock()

        for conn in conns {
            let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
            let context = NWConnection.ContentContext(identifier: "textContext", metadata: [metadata])
            conn.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
        }
    }

    private func sendProfileSnapshot(to connection: NWConnection) {
        let snapshot = buildProfileSnapshot()
        sendJson(snapshot, to: connection)
    }

    private func buildProfileSnapshot() -> [String: Any] {
        let slots = PhoneDeckService.shared.slots
        var controls: [[String: Any]] = []

        for slot in slots.prefix(6) {
            var controlDict: [String: Any] = [
                "id": slot.id,
                "label": slot.label,
                "bundleId": slot.bundleId
            ]
            if let icon = getAppIconBase64(bundleId: slot.bundleId) {
                controlDict["iconPngBase64"] = icon
            }
            controls.append(controlDict)
        }

        return [
            "protocolVersion": 1,
            "type": "profile.snapshot",
            "requestId": UUID().uuidString,
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "payload": [
                "id": "main-deck",
                "name": "NotchDeck",
                "revision": 1,
                "maxColumns": 3,
                "maxRows": 3,
                "controls": controls
            ]
        ]
    }

    private func sendJson(_ dict: [String: Any], to connection: NWConnection) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "textContext", metadata: [metadata])
        connection.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
    }

    // MARK: - Icon Base64 Extraction

    public func getAppIconBase64(bundleId: String, maxDimension: CGFloat = 128) -> String? {
        guard !bundleId.isEmpty && bundleId != "empty" else { return nil }
        if let cached = iconCache.object(forKey: bundleId as NSString) {
            return cached as String
        }

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }

        let icon = NSWorkspace.shared.icon(forFile: appURL.path)
        var proposedRect = NSRect(x: 0, y: 0, width: maxDimension, height: maxDimension)
        guard let cgImage = icon.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = NSSize(width: maxDimension, height: maxDimension)

        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }

        let base64 = pngData.base64EncodedString()
        iconCache.setObject(base64 as NSString, forKey: bundleId as NSString)
        return base64
    }

    // MARK: - UDP Auto-Discovery Responder (Port 8766)

    private func startUdpDiscoveryResponder() {
        guard let nwPort = NWEndpoint.Port(rawValue: udpPort) else { return }
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true

        do {
            let listener = try NWListener(using: params, on: nwPort)
            self.udpListener = listener

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleUdpPacket(connection)
            }

            listener.start(queue: .global(qos: .utility))
            print("📡 [NotchDeck] UDP Auto-Discovery Responder active on port \(udpPort)")
        } catch {
            print("⚠️ [NotchDeck] UDP Responder could not bind to port \(udpPort): \(error)")
        }
    }

    private func handleUdpPacket(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .utility))
        connection.receiveMessage { [weak self] content, _, _, _ in
            guard let self = self, let content = content, let query = String(data: content, encoding: .utf8) else {
                return
            }

            if query.contains("NOTCHDECK_DISCOVER") {
                let myIp = NetworkHelper.shared.activeIPAddress
                let response = "NOTCHDECK_HOST:\(myIp):\(self.port)\n"
                if let respData = response.data(using: .utf8) {
                    connection.send(content: respData, completion: .contentProcessed({ _ in }))
                }
            }
        }
    }

    // MARK: - Periodic UDP Beacon Broadcast

    private func startUdpBeacon() {
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now() + 1.0, repeating: 3.0)
        timer.setEventHandler { [weak self] in
            self?.sendUdpBeacon()
        }
        timer.resume()
        self.udpBeaconTimer = timer
    }

    private func sendUdpBeacon() {
        let myIp = NetworkHelper.shared.activeIPAddress
        guard !myIp.isEmpty && myIp != "127.0.0.1" else { return }

        guard let nwPort = NWEndpoint.Port(rawValue: udpPort) else { return }
        let broadcastEndpoint = NWEndpoint.hostPort(host: "255.255.255.255", port: nwPort)
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true

        let connection = NWConnection(to: broadcastEndpoint, using: params)
        connection.start(queue: .global(qos: .utility))

        let message = "NOTCHDECK_HOST:\(myIp):\(self.port)\n"
        if let data = message.data(using: .utf8) {
            connection.send(content: data, completion: .contentProcessed({ _ in
                connection.cancel()
            }))
        }
    }
}
