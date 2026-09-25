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
            .tabItem { Label("Appearance", systemImage: "sparkles") }
            .padding()
        }
        .frame(width: 420, height: 260)
    }
}
