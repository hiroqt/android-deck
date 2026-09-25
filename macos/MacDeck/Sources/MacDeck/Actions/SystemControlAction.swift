import Foundation
import CoreAudio
import AppKit
import CoreGraphics

public struct AudioOutputDevice: Codable, Equatable, Sendable {
    public let id: UInt32
    public let name: String
    public let isDefault: Bool
}

public final class SystemControlAction: DeckActionHandler, @unchecked Sendable {
    public let actionType = "system_control"

    public init() {}

    public func execute(controlId: String, parameters: [String: String]) async throws -> ActionResultPayload {
        let event = parameters["event"] ?? "tap"

        switch controlId {
        case "sys_bluetooth":
            toggleBluetooth(event: event)
            return ActionResultPayload.ok(controlId: controlId)

        case "sys_wifi":
            toggleWifi(event: event)
            return ActionResultPayload.ok(controlId: controlId)

        case "sys_volume":
            setVolume(event: event)
            return ActionResultPayload.ok(controlId: controlId)

        case "sys_audio_device":
            let success = selectAudioDevice(event: event)
            if success {
                return ActionResultPayload.ok(controlId: controlId)
            } else {
                return ActionResultPayload.error(
                    controlId: controlId,
                    code: "DEVICE_NOT_FOUND",
                    message: "Specified audio output device not found"
                )
            }

        case "sys_brightness":
            setBrightness(event: event)
            return ActionResultPayload.ok(controlId: controlId)

        default:
            throw DeckActionError.actionUnknown(controlId)
        }
    }

    // MARK: - Bluetooth Control
    private func toggleBluetooth(event: String) {
        // Check if blueutil exists
        let checkProcess = Process()
        checkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        checkProcess.arguments = ["blueutil"]
        let pipe = Pipe()
        checkProcess.standardOutput = pipe
        try? checkProcess.run()
        checkProcess.waitUntilExit()

        if checkProcess.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            if !path.isEmpty {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: path)
                if event == "on" {
                    proc.arguments = ["-p", "1"]
                } else if event == "off" {
                    proc.arguments = ["-p", "0"]
                } else {
                    proc.arguments = ["-p", "switch"]
                }
                try? proc.run()
                return
            }
        }

        // AppleScript fallback for macOS ControlCenter
        let script = """
        tell application "System Events"
            tell process "ControlCenter"
                -- Trigger Bluetooth settings/toggle
            end tell
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    // MARK: - Wi-Fi Control
    private func toggleWifi(event: String) {
        let wifiDevice = getWifiDeviceName()

        if event == "on" {
            setWifiPower(device: wifiDevice, state: "on")
        } else if event == "off" {
            setWifiPower(device: wifiDevice, state: "off")
        } else {
            let isCurrentlyOn = isWifiPowerOn(device: wifiDevice)
            setWifiPower(device: wifiDevice, state: isCurrentlyOn ? "off" : "on")
        }
    }

    private func getWifiDeviceName() -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        proc.arguments = ["-listallhardwareports"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        let lines = output.components(separatedBy: .newlines)

        var foundWifi = false
        for line in lines {
            if line.contains("Hardware Port: Wi-Fi") {
                foundWifi = true
            } else if foundWifi && line.contains("Device:") {
                let parts = line.components(separatedBy: ":")
                if parts.count > 1 {
                    return parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return "en0"
    }

    private func isWifiPowerOn(device: String) -> Bool {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        proc.arguments = ["-getairportpower", device]
        let pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        return output.localizedCaseInsensitiveContains(": On")
    }

    private func setWifiPower(device: String, state: String) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        proc.arguments = ["-setairportpower", device, state]
        try? proc.run()
    }

    // MARK: - Volume Control
    private func setVolume(event: String) {
        if event.hasPrefix("set:") {
            let levelStr = event.replacingOccurrences(of: "set:", with: "")
            if let level = Int(levelStr) {
                let clamped = max(0, min(100, level))
                let script = "set volume output volume \(clamped)"
                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    appleScript.executeAndReturnError(&error)
                }
            }
        } else if event == "mute" {
            let script = "set volume output muted not (output muted of (get volume settings))"
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
            }
        }
    }

    // MARK: - Audio Device Switching via CoreAudio
    public static func getAvailableAudioOutputDevices() -> [AudioOutputDevice] {
        var propertySize: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propertySize)
        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        guard deviceCount > 0 else { return [] }

        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propertySize, &deviceIDs)

        var defaultOutputAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var defaultID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &defaultOutputAddr, 0, nil, &size, &defaultID)

        var result: [AudioOutputDevice] = []
        for id in deviceIDs {
            var streamAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            var streamSize: UInt32 = 0
            AudioObjectGetPropertyDataSize(id, &streamAddr, 0, nil, &streamSize)
            if streamSize > 0 {
                var nameSize: UInt32 = UInt32(MemoryLayout<CFString>.size)
                var nameAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyDeviceNameCFString,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )
                var cfName: Unmanaged<CFString>?
                AudioObjectGetPropertyData(id, &nameAddr, 0, nil, &nameSize, &cfName)
                if let name = cfName?.takeRetainedValue() as String? {
                    result.append(AudioOutputDevice(id: id, name: name, isDefault: id == defaultID))
                }
            }
        }
        return result
    }

    private func selectAudioDevice(event: String) -> Bool {
        let targetName: String
        if event.hasPrefix("select:") {
            targetName = event.replacingOccurrences(of: "select:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            targetName = event.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let devices = Self.getAvailableAudioOutputDevices()
        guard let target = devices.first(where: {
            $0.name.localizedCaseInsensitiveContains(targetName) ||
            targetName.localizedCaseInsensitiveContains($0.name)
        }) else {
            return false
        }

        var targetID = target.id
        var defaultOutputAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultOutputAddr,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &targetID
        )
        return status == noErr
    }

    // MARK: - Brightness Control
    private func setBrightness(event: String) {
        if event.hasPrefix("set:") {
            let levelStr = event.replacingOccurrences(of: "set:", with: "")
            if let level = Float(levelStr) {
                let clamped = max(0.0, min(1.0, level / 100.0))
                typealias DisplayServicesSetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32
                if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY),
                   let setSym = dlsym(handle, "DisplayServicesSetBrightness") {
                    let setBrightnessFunc = unsafeBitCast(setSym, to: DisplayServicesSetBrightnessFunc.self)
                    _ = setBrightnessFunc(CGMainDisplayID(), clamped)
                }
            }
        }
    }
}
