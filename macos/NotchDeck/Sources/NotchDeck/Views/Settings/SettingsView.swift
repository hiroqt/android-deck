import SwiftUI

public struct SettingsView: View {
    @ObservedObject public var configManager: ConfigManager
    @ObservedObject public var phoneDeckService = PhoneDeckService.shared

    @State private var newPresetName: String = ""
    @State private var copiedDownloadLink: Bool = false
    @State private var copiedHostAddress: Bool = false

    public init(configManager: ConfigManager = .shared, phoneDeckService: PhoneDeckService = .shared) {
        self.configManager = configManager
        self.phoneDeckService = phoneDeckService
    }

    public var body: some View {
        TabView {
            // General Tab: Screen Placement & Deck Presets
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    // Section 1: Screen Placement
                    SettingsSectionCard(
                        title: "Screen Placement",
                        subtitle: "Select which display edge the notch docks to, or drag it directly on screen.",
                        icon: "display"
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Dock Position:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)

                                Spacer()

                                Picker("Dock Position", selection: Binding(
                                    get: { configManager.config.edge },
                                    set: { newEdge in
                                        NotchWindowController.shared.moveTo(
                                            edge: newEdge,
                                            positionRatio: configManager.config.sidePositionRatio,
                                            animated: true
                                        )
                                    }
                                )) {
                                    ForEach(NotchEdge.allCases) { edge in
                                        Text(edge.title).tag(edge)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                .frame(width: 240)
                            }

                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 11))
                                Text("Tip: You can also drag the notch handle directly to the top or side edge of your screen for a smooth liquid snap.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Section 2: Deck Presets (6 Apps)
                    SettingsSectionCard(
                        title: "Deck Presets (6 Apps)",
                        subtitle: "Manage and switch between your personalized 6-app presets.",
                        icon: "square.grid.2x3"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(phoneDeckService.presets) { preset in
                                let isActive = phoneDeckService.activePresetId == preset.id
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(preset.name)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))

                                        if isActive {
                                            Text("ACTIVE")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.green)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(Color.green.opacity(0.18)))
                                        }

                                        Spacer()

                                        if !isActive {
                                            Button("Apply") {
                                                withAnimation(.easeInOut(duration: 0.22)) {
                                                    phoneDeckService.applyPreset(id: preset.id)
                                                }
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .controlSize(.small)
                                        }

                                        if phoneDeckService.presets.count > 1 {
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.22)) {
                                                    phoneDeckService.deletePreset(id: preset.id)
                                                }
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.secondary)
                                            }
                                            .buttonStyle(.plain)
                                            .help("Delete Preset")
                                        }
                                    }

                                    // 6 Apps mini grid (3 columns x 2 rows) - all apps fully visible
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                                        ForEach(preset.slots.prefix(6)) { slot in
                                            HStack(spacing: 4) {
                                                Image(systemName: slot.isEmpty ? "plus.circle" : "app.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(slot.isEmpty ? .secondary.opacity(0.6) : .accentColor)

                                                Text(slot.isEmpty ? "Slot \(slot.index + 1)" : slot.label)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(slot.isEmpty ? .secondary : .primary)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 5)
                                                    .fill(Color(NSColor.textBackgroundColor).opacity(0.6))
                                            )
                                        }
                                    }
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isActive ? Color.accentColor.opacity(0.06) : Color(NSColor.textBackgroundColor).opacity(0.3))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isActive ? Color.accentColor.opacity(0.3) : Color(NSColor.separatorColor).opacity(0.4), lineWidth: 1)
                                )
                            }

                            // Save current deck as new preset
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Save Current Deck as Preset")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)

                                HStack(spacing: 8) {
                                    TextField("Preset Name (e.g. Work, Gaming, Editing)", text: $newPresetName)
                                        .textFieldStyle(.roundedBorder)

                                    Button("Save Preset") {
                                        let name = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
                                        phoneDeckService.saveCurrentAsPreset(name: name)
                                        newPresetName = ""
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                            .padding(.top, 4)

                            Divider()
                                .padding(.vertical, 2)

                            // Reset Deck to Defaults
                            HStack {
                                Button(role: .destructive, action: {
                                    phoneDeckService.resetDefaults()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Reset Deck to Defaults")
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Spacer()
                            }
                        }
                    }
                }
                .padding(20)
            }
            .tabItem { Label("General", systemImage: "gearshape") }

            // Appearance Tab: Live Liquid Glass Controls
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    SettingsSectionCard(
                        title: "Liquid Glass Customization",
                        subtitle: "Fine-tune the acrylic translucency, rim reflection, and backlight glow.",
                        icon: "sparkles"
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            // Slider 1: Translucency
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Glass Translucency & Opacity")
                                        .font(.system(size: 12, weight: .medium))
                                    Spacer()
                                    Text("\(Int(configManager.config.appearance.glassTintOpacity * 100))%")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                }
                                Slider(
                                    value: Binding(
                                        get: { configManager.config.appearance.glassTintOpacity },
                                        set: {
                                            var updated = configManager.config
                                            updated.appearance.glassTintOpacity = $0
                                            try? configManager.saveConfig(updated)
                                        }
                                    ),
                                    in: 0.30...0.95,
                                    step: 0.05
                                )
                                Text("Controls glass transparency and desktop wallpaper blur penetration.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            // Slider 2: Specular Rim
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Specular Highlight Intensity")
                                        .font(.system(size: 12, weight: .medium))
                                    Spacer()
                                    Text("\(Int(configManager.config.appearance.specularIntensity * 100))%")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                }
                                Slider(
                                    value: Binding(
                                        get: { configManager.config.appearance.specularIntensity },
                                        set: {
                                            var updated = configManager.config
                                            updated.appearance.specularIntensity = $0
                                            try? configManager.saveConfig(updated)
                                        }
                                    ),
                                    in: 0.10...1.00,
                                    step: 0.05
                                )
                                Text("Light reflection on the liquid curvature and rim edges.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            // Toggle: Ambient Glow
                            Toggle(isOn: Binding(
                                get: { configManager.config.appearance.ambientBacklightEnabled },
                                set: {
                                    var updated = configManager.config
                                    updated.appearance.ambientBacklightEnabled = $0
                                    try? configManager.saveConfig(updated)
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ambient Backlight Glow")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Dynamic lighting aura along the dock perimeter.")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)
                        }
                    }

                    // Live Glass Preview Card
                    SettingsSectionCard(
                        title: "Live Glass Preview",
                        subtitle: "Real-time preview of your liquid glass appearance settings against wallpaper.",
                        icon: "eye"
                    ) {
                        ZStack {
                            // Background wallpaper simulation
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.4),
                                            Color.purple.opacity(0.35),
                                            Color.black.opacity(0.85)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 90)

                            // Centered liquid glass preview component
                            ZStack {
                                LiquidGlassBackground(
                                    settings: configManager.config.appearance,
                                    edge: .top,
                                    isExpanded: false
                                )

                                HStack(spacing: 8) {
                                    Image(systemName: "square.grid.2x2.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.cyan)

                                    Text("Liquid Glass Active")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: 220, height: 40)
                        }
                        .frame(height: 90)
                    }
                }
                .padding(20)
            }
            .tabItem { Label("Appearance", systemImage: "paintbrush") }

            // Android App Tab
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    SettingsSectionCard(
                        title: "Wireless APK Download Portal",
                        subtitle: "Scan with your phone's camera to open the download platform and install the latest APK build.",
                        icon: "qrcode.viewfinder"
                    ) {
                        QRCodeCardView(phoneDeckService: phoneDeckService)
                    }

                    SettingsSectionCard(
                        title: "Stream Deck Connection",
                        subtitle: "Server endpoint for real-time app grid synchronization.",
                        icon: "antenna.radiowaves.left.and.right"
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Mac Host Address:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(localIPAddress):8765")
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                }

                                Spacer()

                                Button(copiedHostAddress ? "Copied!" : "Copy Address") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString("\(localIPAddress):8765", forType: .string)
                                    copiedHostAddress = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        copiedHostAddress = false
                                    }
                                }
                                .controlSize(.small)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.textBackgroundColor)))

                            // Phone connection status banner
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(phoneDeckService.isDeviceConnected ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)

                                if phoneDeckService.isDeviceConnected {
                                    Text("Connected: \(phoneDeckService.connectedDeviceName ?? "Android Device")")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.green)

                                    if let battery = phoneDeckService.batteryLevel {
                                        Text("(\(battery)%\(phoneDeckService.isCharging ? " ⚡" : ""))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("Waiting for phone connection...")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(20)
            }
            .tabItem { Label("Android App", systemImage: "iphone") }
        }
        .frame(width: 520, height: 560)
    }

    private var localIPAddress: String {
        NetworkHelper.localIPAddress
    }
}

// MARK: - Reusable Section Card Container
private struct SettingsSectionCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                Spacer()
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 0.8)
            )
        }
    }
}
