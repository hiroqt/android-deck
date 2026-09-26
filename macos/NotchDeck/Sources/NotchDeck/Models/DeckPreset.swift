import Foundation

/// A saved preset of 6 deck app slots with a custom user-defined name.
public struct DeckPreset: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var slots: [PhoneDeckSlot] // Exactly 6 app slots

    public init(id: UUID = UUID(), name: String, slots: [PhoneDeckSlot]) {
        self.id = id
        self.name = name
        self.slots = slots
    }

    public static func defaultPresets() -> [DeckPreset] {
        return [
            DeckPreset(
                name: "Development",
                slots: [
                    PhoneDeckSlot(id: "app-1", index: 0, label: "Antigravity IDE", bundleId: "com.google.antigravity-ide"),
                    PhoneDeckSlot(id: "app-2", index: 1, label: "Discord", bundleId: "com.hnc.Discord"),
                    PhoneDeckSlot(id: "app-3", index: 2, label: "Brave Browser", bundleId: "com.brave.Browser"),
                    PhoneDeckSlot(id: "app-4", index: 3, label: "ChatGPT", bundleId: "com.openai.codex"),
                    PhoneDeckSlot(id: "app-5", index: 4, label: "Orca", bundleId: "com.stablyai.orca"),
                    PhoneDeckSlot(id: "app-6", index: 5, label: "Android Studio", bundleId: "com.google.android.studio")
                ]
            ),
            DeckPreset(
                name: "Productivity",
                slots: [
                    PhoneDeckSlot(id: "app-1", index: 0, label: "VS Code", bundleId: "com.microsoft.VSCode"),
                    PhoneDeckSlot(id: "app-2", index: 1, label: "Terminal", bundleId: "com.apple.Terminal"),
                    PhoneDeckSlot(id: "app-3", index: 2, label: "Safari", bundleId: "com.apple.Safari"),
                    PhoneDeckSlot(id: "app-4", index: 3, label: "Finder", bundleId: "com.apple.finder"),
                    PhoneDeckSlot(id: "app-5", index: 4, label: "Notes", bundleId: "com.apple.Notes"),
                    PhoneDeckSlot(id: "app-6", index: 5, label: "Music", bundleId: "com.apple.Music")
                ]
            ),
            DeckPreset(
                name: "Media & Tools",
                slots: [
                    PhoneDeckSlot(id: "app-1", index: 0, label: "Spotify", bundleId: "com.spotify.client"),
                    PhoneDeckSlot(id: "app-2", index: 1, label: "Discord", bundleId: "com.hnc.Discord"),
                    PhoneDeckSlot(id: "app-3", index: 2, label: "Chrome", bundleId: "com.google.Chrome"),
                    PhoneDeckSlot(id: "app-4", index: 3, label: "Photos", bundleId: "com.apple.Photos"),
                    PhoneDeckSlot(id: "app-5", index: 4, label: "Calculator", bundleId: "com.apple.calculator"),
                    PhoneDeckSlot(id: "app-6", index: 5, label: "Settings", bundleId: "com.apple.systempreferences")
                ]
            )
        ]
    }
}
