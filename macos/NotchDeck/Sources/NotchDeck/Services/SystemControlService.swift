import Foundation
import AppKit
import CoreAudio
import CoreGraphics

public final class SystemControlService {
    public static let shared = SystemControlService()

    public init() {}

    public func isMicMuted() -> Bool {
        let script = "input volume of (get volume settings)"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let output = appleScript.executeAndReturnError(&error)
            return output.int32Value == 0
        }
        return false
    }

    @discardableResult
    public func toggleMicMute() -> Bool {
        let script = """
        set curVol to input volume of (get volume settings)
        if curVol is 0 then
            set volume input volume 75
            return false
        else
            set volume input volume 0
            return true
        end if
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let output = appleScript.executeAndReturnError(&error)
            return output.booleanValue
        }
        return false
    }

    public func toggleVolumeMute() {
        let script = "set volume output muted not (output muted of (get volume settings))"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    public func captureInteractiveScreenshot() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-c"] // Interactive capture to clipboard
        try? process.run()
    }

    public func lockScreen() {
        let script = """
        tell application "System Events" to sleep
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    // MARK: - Output Volume
    public func getOutputVolume() -> Int {
        let script = "output volume of (get volume settings)"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let output = appleScript.executeAndReturnError(&error)
            return Int(output.int32Value)
        }
        return 75
    }

    public func setOutputVolume(_ volume: Int) {
        let clamped = max(0, min(100, volume))
        let script = "set volume output volume \(clamped)"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    // MARK: - Audio Output Devices (CoreAudio)
    public func getAudioOutputDevices() -> [String] {
        var propertySize: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propertySize)
        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        guard deviceCount > 0 else { return ["MacBook Speakers"] }

        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propertySize, &deviceIDs)

        var result: [String] = []
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
                    result.append(name)
                }
            }
        }
        return result.isEmpty ? ["MacBook Speakers"] : result
    }

    public func getDefaultAudioOutputDevice() -> String {
        var defaultOutputAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var defaultID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &defaultOutputAddr, 0, nil, &size, &defaultID)

        var nameSize: UInt32 = UInt32(MemoryLayout<CFString>.size)
        var nameAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var cfName: Unmanaged<CFString>?
        AudioObjectGetPropertyData(defaultID, &nameAddr, 0, nil, &nameSize, &cfName)
        return (cfName?.takeRetainedValue() as String?) ?? "MacBook Speakers"
    }

    @discardableResult
    public func setDefaultAudioOutputDevice(name: String) -> Bool {
        var propertySize: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propertySize)
        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propertySize, &deviceIDs)

        for id in deviceIDs {
            var nameSize: UInt32 = UInt32(MemoryLayout<CFString>.size)
            var nameAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceNameCFString,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var cfName: Unmanaged<CFString>?
            AudioObjectGetPropertyData(id, &nameAddr, 0, nil, &nameSize, &cfName)
            if let devName = cfName?.takeRetainedValue() as String?,
               devName.localizedCaseInsensitiveContains(name) || name.localizedCaseInsensitiveContains(devName) {
                var targetID = id
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
        }
        return false
    }

    // MARK: - Wi-Fi Control
    public func isWifiOn() -> Bool {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        proc.arguments = ["-getairportpower", "en0"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        return output.localizedCaseInsensitiveContains(": On")
    }

    public func toggleWifi() {
        let currentlyOn = isWifiOn()
        let newState = currentlyOn ? "off" : "on"
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        proc.arguments = ["-setairportpower", "en0", newState]
        try? proc.run()
    }

    // MARK: - Bluetooth Control
    public func isBluetoothOn() -> Bool {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        proc.arguments = ["SPBluetoothDataType"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        return output.contains("State: On")
    }

    public func toggleBluetooth() {
        // Toggle via blueutil if available, otherwise launch Bluetooth settings
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        proc.arguments = ["blueutil"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()

        if proc.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            if !path.isEmpty {
                let blueutilProc = Process()
                blueutilProc.executableURL = URL(fileURLWithPath: path)
                blueutilProc.arguments = ["-p", "switch"]
                try? blueutilProc.run()
                return
            }
        }

        // Open Bluetooth Preferences as clean fallback
        if let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Brightness Control
    public func getBrightness() -> Float {
        typealias DisplayServicesGetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY),
           let getSym = dlsym(handle, "DisplayServicesGetBrightness") {
            let getBrightnessFunc = unsafeBitCast(getSym, to: DisplayServicesGetBrightnessFunc.self)
            var b: Float = 0.8
            _ = getBrightnessFunc(CGMainDisplayID(), &b)
            return b
        }
        return 0.8
    }

    public func setBrightness(_ level: Float) {
        let clamped = max(0.0, min(1.0, level))
        typealias DisplayServicesSetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY),
           let setSym = dlsym(handle, "DisplayServicesSetBrightness") {
            let setBrightnessFunc = unsafeBitCast(setSym, to: DisplayServicesSetBrightnessFunc.self)
            _ = setBrightnessFunc(CGMainDisplayID(), clamped)
        }
    }
}
