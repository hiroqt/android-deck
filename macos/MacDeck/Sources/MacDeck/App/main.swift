import Foundation
import AppKit

@main
struct Main {
    static func main() async {
        let server = WebSocketServer.shared
        let profileManager = ProfileManager.shared
        let scanner = AppScanner.shared

        do {
            try server.start()
        } catch {
            print("❌ Failed to start server: \(error)")
            exit(1)
        }

        print("\n==================================================")
        print("  🚀 MacDeck macOS Host Agent is Running!")
        print("  📡 WebSocket Listening Port: \(server.port)")
        print("==================================================")
        print("🌐 LAN IP Addresses (for Wi-Fi connection):")
        let ips = NetworkUtils.getLocalIPAddresses()
        if ips.isEmpty {
            print("   (No active Wi-Fi/LAN interface found)")
        } else {
            for ip in ips {
                print("   👉 \(ip)")
            }
        }
        print("\n🔌 USB Connection (Recommended):")
        print("   Run: ./scripts/usb/connect.sh")
        print("   Then on Android connect to: ws://127.0.0.1:\(server.port)")
        print("==================================================")
        print("Commands available:")
        print("  list               - Show current 6 configured apps")
        print("  scan               - Scan and list installed Mac apps")
        print("  set <slot> <bId>   - Change slot (1-6) to bundleId (e.g.: set 1 com.apple.Safari)")
        print("  launch <slot>      - Test launch app in slot (1-6)")
        print("  quit               - Stop server and exit")
        print("==================================================\n")

        // Print initial profile
        printSlots(profileManager.getStoredSlots())

        // Read standard input in background
        let inputHandle = FileHandle.standardInput

        while true {
            let lineData = inputHandle.availableData
            guard !lineData.isEmpty,
                  let rawText = String(data: lineData, encoding: .utf8) else {
                try? await Task.sleep(nanoseconds: 100_000_000)
                continue
            }

            for rawLine in rawText.components(separatedBy: .newlines) {
                let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty else { continue }

                let parts = line.split(separator: " ").map(String.init)
                guard let cmd = parts.first?.lowercased() else { continue }

                switch cmd {
            case "list":
                printSlots(profileManager.getStoredSlots())

            case "scan":
                let apps = scanner.scanInstalledApps()
                print("Found \(apps.count) installed applications:")
                for app in apps.prefix(30) {
                    print("  - \(app.name) [\(app.bundleId)]")
                }
                if apps.count > 30 {
                    print("  ... and \(apps.count - 30) more. (Use exact bundleId with 'set')")
                }

            case "set":
                if parts.count >= 3, let slotNum = Int(parts[1]), slotNum >= 1 && slotNum <= 6 {
                    let bundleId = parts[2]
                    let apps = scanner.scanInstalledApps()
                    if let found = apps.first(where: { $0.bundleId.lowercased() == bundleId.lowercased() }) {
                        profileManager.updateSlot(index: slotNum - 1, app: found)
                        print("✅ Slot \(slotNum) updated to '\(found.name)' (\(found.bundleId))!")
                    } else {
                        // Create custom entry with bundleId
                        let customApp = InstalledApp(name: bundleId.components(separatedBy: ".").last?.capitalized ?? bundleId, path: "", bundleId: bundleId)
                        profileManager.updateSlot(index: slotNum - 1, app: customApp)
                        print("✅ Slot \(slotNum) updated with bundleId: \(bundleId)")
                    }
                    printSlots(profileManager.getStoredSlots())
                } else {
                    print("Usage: set <1-6> <bundleId>")
                }

            case "launch":
                if parts.count >= 2, let slotNum = Int(parts[1]), slotNum >= 1 && slotNum <= 6 {
                    let controlId = "app-\(slotNum)"
                    print("🚀 Testing launch for slot \(slotNum) (\(controlId))...")
                    let result = await ActionRegistry.shared.invoke(controlId: controlId, event: "tap")
                    print("Result: status=\(result.status), code=\(result.errorCode ?? "nil"), msg=\(result.errorMessage ?? "nil")")
                } else {
                    print("Usage: launch <1-6>")
                }

            case "quit", "exit":
                print("Stopping MacDeck...")
                server.stop()
                exit(0)

            default:
                print("Unknown command: '\(cmd)'. Type 'list', 'scan', 'set <1-6> <bundleId>', 'launch <1-6>', or 'quit'.")
            }
            }
        }
    }

    private static func printSlots(_ slots: [StoredAppSlot]) {
        print("\n📱 Active Deck Slots (Max 6):")
        for (i, slot) in slots.enumerated() {
            print("  Slot \(i + 1) [\(slot.id)]: \"\(slot.label)\" → \(slot.bundleId)")
        }
        print("")
    }
}
