import Foundation
import Network
import Combine

public enum NetworkInterfaceType: String, CaseIterable, Identifiable, Codable {
    case wifi = "Wi-Fi"
    case ethernet = "Ethernet"
    case hotspot = "Hotspot"
    case bridge = "USB / Bridge"
    case other = "LAN"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .wifi: return "wifi"
        case .ethernet: return "cable.connector"
        case .hotspot: return "personalhotspot"
        case .bridge: return "link"
        case .other: return "network"
        }
    }
}

public struct NetworkInterfaceInfo: Identifiable, Hashable, Equatable {
    public let id: String
    public let name: String
    public let ip: String
    public let type: NetworkInterfaceType
    public let isPrimary: Bool

    public init(name: String, ip: String, type: NetworkInterfaceType, isPrimary: Bool) {
        self.id = "\(name):\(ip)"
        self.name = name
        self.ip = ip
        self.type = type
        self.isPrimary = isPrimary
    }

    public var displayName: String {
        "\(type.rawValue) (\(name)): \(ip)"
    }
}

public final class NetworkHelper: ObservableObject {
    public static let shared = NetworkHelper()

    /// Backward compatibility accessor that dynamically returns the active IP address.
    public static var localIPAddress: String {
        shared.activeIPAddress
    }

    @Published public private(set) var activeIPAddress: String = "127.0.0.1"
    @Published public private(set) var availableInterfaces: [NetworkInterfaceInfo] = []
    @Published public private(set) var selectedInterfaceId: String? = nil

    private let pathMonitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.macdeck.notchdeck.networkmonitor", qos: .utility)

    public init() {
        self.pathMonitor = NWPathMonitor()
        scanInterfaces()
        startMonitoring()
    }

    deinit {
        pathMonitor.cancel()
    }

    private func startMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.scanInterfaces()
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    /// Explicitly refresh available network interfaces and adapt IP dynamically.
    public func refresh() {
        scanInterfaces()
    }

    /// Select a specific network interface to bind the portal and QR code to, or nil for auto-selection.
    public func selectInterface(id: String?) {
        selectedInterfaceId = id
        updateActiveIP()
    }

    private func scanInterfaces() {
        var detected: [NetworkInterfaceInfo] = []
        let primaryIP = detectPrimaryRouteIP()

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            fallbackToPrimary(primaryIP)
            return
        }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let ifa = ptr.pointee
            let flags = Int32(ifa.ifa_flags)

            // Must be AF_INET (IPv4)
            guard let addr = ifa.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) else {
                continue
            }

            // Must be UP and RUNNING, and NOT a LOOPBACK
            let isUp = (flags & IFF_UP) != 0
            let isRunning = (flags & IFF_RUNNING) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0

            guard isUp && isRunning && !isLoopback else {
                continue
            }

            let name = String(cString: ifa.ifa_name)

            // Exclude virtual/tunnel interfaces that phones cannot reach
            if name.hasPrefix("utun") || name.hasPrefix("awdl") || name.hasPrefix("llw") ||
               name.hasPrefix("gif") || name.hasPrefix("stf") || name == "lo0" {
                continue
            }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(
                addr,
                socklen_t(addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            let ip = String(cString: hostname)

            // Filter invalid, loopback or link-local auto-configuration IPs
            guard !ip.isEmpty,
                  !ip.hasPrefix("127."),
                  !ip.hasPrefix("169.254."),
                  ip != "0.0.0.0" else {
                continue
            }

            // Interface classification
            let type: NetworkInterfaceType
            if name == "en0" {
                type = .wifi
            } else if name.hasPrefix("bridge") || name.hasPrefix("rndis") {
                type = .bridge
            } else if name.hasPrefix("ap") || name.hasPrefix("pdp_ip") {
                type = .hotspot
            } else if name.hasPrefix("en") {
                type = .ethernet
            } else {
                type = .other
            }

            let isPrimary = (primaryIP != nil && ip == primaryIP)
            let info = NetworkInterfaceInfo(name: name, ip: ip, type: type, isPrimary: isPrimary)

            // Avoid duplicates
            if !detected.contains(where: { $0.ip == ip }) {
                detected.append(info)
            }
        }

        // Sort interfaces: Primary first, then Wi-Fi (en0), then Ethernet, then Bridge/Hotspot
        detected.sort { a, b in
            if a.isPrimary != b.isPrimary {
                return a.isPrimary
            }
            if a.type == .wifi && b.type != .wifi {
                return true
            }
            if b.type == .wifi && a.type != .wifi {
                return false
            }
            return a.name < b.name
        }

        self.availableInterfaces = detected
        updateActiveIP()
    }

    private func updateActiveIP() {
        if let selectedId = selectedInterfaceId,
           let chosen = availableInterfaces.first(where: { $0.id == selectedId }) {
            self.activeIPAddress = chosen.ip
            return
        }

        if let primary = availableInterfaces.first(where: { $0.isPrimary }) {
            self.activeIPAddress = primary.ip
            return
        }

        if let first = availableInterfaces.first {
            self.activeIPAddress = first.ip
            return
        }

        // If no interface was enumerated via getifaddrs, try socket detection fallback
        if let primaryFallback = detectPrimaryRouteIP() {
            self.activeIPAddress = primaryFallback
            return
        }

        self.activeIPAddress = "127.0.0.1"
    }

    private func fallbackToPrimary(_ primaryIP: String?) {
        if let ip = primaryIP, !ip.isEmpty {
            self.availableInterfaces = [
                NetworkInterfaceInfo(name: "default", ip: ip, type: .wifi, isPrimary: true)
            ]
            self.activeIPAddress = ip
        } else {
            self.availableInterfaces = []
            self.activeIPAddress = "127.0.0.1"
        }
    }

    /// Uses the OS routing table via dummy UDP socket connection to find the outgoing LAN IP.
    private func detectPrimaryRouteIP() -> String? {
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(53).bigEndian
        inet_pton(AF_INET, "1.1.1.1", &addr.sin_addr)

        let sock = socket(AF_INET, SOCK_DGRAM, 0)
        guard sock >= 0 else { return nil }
        defer { close(sock) }

        var copyAddr = addr
        let connectRes = withUnsafePointer(to: &copyAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                connect(sock, saPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard connectRes == 0 else { return nil }

        var localAddr = sockaddr_in()
        var localLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        let nameRes = withUnsafeMutablePointer(to: &localAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                getsockname(sock, saPtr, &localLen)
            }
        }
        guard nameRes == 0 else { return nil }

        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        inet_ntop(AF_INET, &localAddr.sin_addr, &buffer, socklen_t(INET_ADDRSTRLEN))
        let ip = String(cString: buffer)
        return (ip.isEmpty || ip.hasPrefix("127.") || ip.hasPrefix("169.254.")) ? nil : ip
    }
}
