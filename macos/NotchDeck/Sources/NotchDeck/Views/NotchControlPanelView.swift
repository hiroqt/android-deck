import SwiftUI
import AppKit

public struct NotchControlPanelView: View {
    @State private var isBluetoothOn: Bool = true
    @State private var isWifiOn: Bool = true
    @State private var volume: Double = 75
    @State private var brightness: Double = 80
    @State private var audioDevices: [String] = []
    @State private var selectedAudioDevice: String = "MacBook Speakers"

    private let systemControl = SystemControlService.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 10) {
            // Row 1: Bluetooth & Wi-Fi Toggles
            HStack(spacing: 12) {
                // Bluetooth Tile
                Button(action: {
                    systemControl.toggleBluetooth()
                    isBluetoothOn.toggle()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: isBluetoothOn ? "antenna.radiowaves.left.and.right" : "slash.circle")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isBluetoothOn ? .cyan : Color.white.opacity(0.4))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isBluetoothOn ? Color.cyan.opacity(0.2) : Color.white.opacity(0.06))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bluetooth")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text(isBluetoothOn ? "On" : "Off")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(isBluetoothOn ? Color.cyan.opacity(0.8) : Color.white.opacity(0.5))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(isBluetoothOn ? 0.10 : 0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(isBluetoothOn ? Color.cyan.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                // Wi-Fi Tile
                Button(action: {
                    systemControl.toggleWifi()
                    isWifiOn.toggle()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: isWifiOn ? "wifi" : "wifi.slash")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(isWifiOn ? .green : Color.white.opacity(0.4))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isWifiOn ? Color.green.opacity(0.2) : Color.white.opacity(0.06))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wi-Fi")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text(isWifiOn ? "Connected" : "Off")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(isWifiOn ? Color.green.opacity(0.8) : Color.white.opacity(0.5))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(isWifiOn ? 0.10 : 0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(isWifiOn ? Color.green.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            // Row 2: Volume + Audio Output Device Selector
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: volume <= 0 ? "speaker.slash.fill" : (volume < 50 ? "speaker.wave.1.fill" : "speaker.wave.3.fill"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)

                    Text("Volume")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.9))

                    Spacer()

                    Text("\(Int(volume))%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                }

                HStack(spacing: 12) {
                    Slider(value: $volume, in: 0...100, onEditingChanged: { editing in
                        if !editing {
                            systemControl.setOutputVolume(Int(volume))
                        }
                    })
                    .accentColor(.cyan)

                    // Output Device Picker Menu
                    Menu {
                        ForEach(audioDevices, id: \.self) { device in
                            Button(action: {
                                selectedAudioDevice = device
                                systemControl.setDefaultAudioOutputDevice(name: device)
                            }) {
                                HStack {
                                    Text(device)
                                    if device == selectedAudioDevice {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: selectedAudioDevice.contains("Headphone") || selectedAudioDevice.contains("AirPod") ? "headphones" : "hifispeaker.fill")
                                .font(.system(size: 10))
                            Text(selectedAudioDevice)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                                .frame(maxWidth: 110)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 8))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                        )
                    }
                    .menuStyle(.borderlessButton)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )

            // Row 3: Brightness Slider
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.yellow)

                    Text("Brightness")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.9))

                    Spacer()

                    Text("\(Int(brightness))%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                }

                Slider(value: $brightness, in: 0...100, onEditingChanged: { editing in
                    if !editing {
                        systemControl.setBrightness(Float(brightness / 100.0))
                    }
                })
                .accentColor(.yellow)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
        .onAppear {
            loadSystemState()
        }
    }

    private func loadSystemState() {
        self.volume = Double(systemControl.getOutputVolume())
        self.brightness = Double(systemControl.getBrightness() * 100)
        self.audioDevices = systemControl.getAudioOutputDevices()
        self.selectedAudioDevice = systemControl.getDefaultAudioOutputDevice()
        self.isWifiOn = systemControl.isWifiOn()
        self.isBluetoothOn = systemControl.isBluetoothOn()
    }
}
