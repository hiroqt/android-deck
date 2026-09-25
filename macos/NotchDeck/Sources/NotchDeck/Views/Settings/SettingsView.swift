import SwiftUI

public struct SettingsView: View {
    @ObservedObject public var configManager: ConfigManager

    public init(configManager: ConfigManager = .shared) {
        self.configManager = configManager
    }

    public var body: some View {
        TabView {
            // General Tab
            Form {
                Section("Deck Layout") {
                    Stepper("Columns: \(configManager.config.gridColumns)", value: Binding(
                        get: { configManager.config.gridColumns },
                        set: {
                            var updated = configManager.config
                            updated.gridColumns = $0
                            try? configManager.saveConfig(updated)
                        }
                    ), in: 4...6)
                }

                Section("Presets") {
                    Button("Reset to Default 10-Slot Deck") {
                        configManager.resetToDefault()
                    }
                    .foregroundColor(.red)
                }
            }
            .tabItem { Label("General", systemImage: "gearshape") }
            .padding()

            // Appearance Tab
            Form {
                Section("Liquid Glass Customization") {
                    Slider(
                        value: Binding(
                            get: { configManager.config.appearance.specularIntensity },
                            set: {
                                var updated = configManager.config
                                updated.appearance.specularIntensity = $0
                                try? configManager.saveConfig(updated)
                            }
                        ),
                        in: 0.1...1.0,
                        step: 0.05
                    ) {
                        Text("Specular Reflection Highlight Rim")
                    }

                    Toggle("Ambient Backlight Glow", isOn: Binding(
                        get: { configManager.config.appearance.ambientBacklightEnabled },
                        set: {
                            var updated = configManager.config
                            updated.appearance.ambientBacklightEnabled = $0
                            try? configManager.saveConfig(updated)
                        }
                    ))
                }
            }
            // Android App Tab
            Form {
                Section("Wireless Download Portal") {
                    Text("Visit on your Android phone's browser:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("http://\(localIPAddress):8080")
                            .font(.system(.body, design: .monospaced))
                            .bold()
                        Spacer()
                        Button("Open") {
                            if let url = URL(string: "http://\(localIPAddress):8080") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }

                    Text("Download & install the APK directly to your phone over local Wi-Fi.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Section("Stream Deck Connection") {
                    HStack {
                        Text("Mac Host Address:")
                        Spacer()
                        Text("\(localIPAddress):8765")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Button("Copy Host Address") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("\(localIPAddress):8765", forType: .string)
                    }
                }
            }
            .tabItem { Label("Android App", systemImage: "iphone") }
            .padding()
        }
        .frame(width: 440, height: 280)
    }

    private var localIPAddress: String {
        var address: String = "192.168.1.3"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return address }
        guard let firstAddr = ifaddr else { return address }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    let found = String(cString: hostname)
                    if !found.isEmpty && found != "127.0.0.1" {
                        return found
                    }
                }
            }
        }
        return address
    }
}
