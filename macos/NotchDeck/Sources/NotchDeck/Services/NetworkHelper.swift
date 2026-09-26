import Foundation

public enum NetworkHelper {
    /// Detects the local IPv4 Wi-Fi or Ethernet LAN address for connecting local devices.
    public static var localIPAddress: String {
        let fallback = "192.168.1.3"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return fallback }
        guard let firstAddr = ifaddr else { return fallback }
        defer { freeifaddrs(ifaddr) }

        var candidateIP: String? = nil

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)

                // Prioritize standard Wi-Fi (en0) or Ethernet (en1-en4)
                if name.hasPrefix("en") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        socklen_t(0),
                        NI_NUMERICHOST
                    )
                    let found = String(cString: hostname)
                    if !found.isEmpty && found != "127.0.0.1" {
                        return found
                    }
                } else if candidateIP == nil && name != "lo0" && !name.hasPrefix("utun") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        socklen_t(0),
                        NI_NUMERICHOST
                    )
                    let found = String(cString: hostname)
                    if !found.isEmpty && found != "127.0.0.1" {
                        candidateIP = found
                    }
                }
            }
        }

        return candidateIP ?? fallback
    }
}
