import Foundation

public struct NotchDeckConfig: Codable, Equatable {
    public var gridColumns: Int
    public var gridRows: Int
    public var slots: [DeckSlot]
    public var appearance: GlassAppearanceSettings

    public init(
        gridColumns: Int = 5,
        gridRows: Int = 2,
        slots: [DeckSlot] = [],
        appearance: GlassAppearanceSettings = GlassAppearanceSettings()
    ) {
        self.gridColumns = gridColumns
        self.gridRows = gridRows
        self.slots = slots
        self.appearance = appearance
    }

    public static func defaultConfig() -> NotchDeckConfig {
        let defaultSlots: [DeckSlot] = [
            DeckSlot(index: 0, title: "Finder", actionType: .appLauncher, target: "com.apple.finder", iconName: "folder.fill"),
            DeckSlot(index: 1, title: "Safari", actionType: .appLauncher, target: "com.apple.Safari", iconName: "safari.fill"),
            DeckSlot(index: 2, title: "Terminal", actionType: .appLauncher, target: "com.apple.Terminal", iconName: "terminal.fill"),
            DeckSlot(index: 3, title: "Music", actionType: .appLauncher, target: "com.apple.Music", iconName: "music.note"),
            DeckSlot(index: 4, title: "Settings", actionType: .appLauncher, target: "com.apple.systempreferences", iconName: "gearshape.fill"),
            DeckSlot(index: 5, title: "Mic Mute", actionType: .systemToggle, target: "micMute", iconName: "mic.fill"),
            DeckSlot(index: 6, title: "Vol Mute", actionType: .systemToggle, target: "volumeMute", iconName: "speaker.slash.fill"),
            DeckSlot(index: 7, title: "Play/Pause", actionType: .mediaControl, target: "playPause", iconName: "playpause.fill"),
            DeckSlot(index: 8, title: "Screenshot", actionType: .systemToggle, target: "screenshot", iconName: "camera.fill"),
            DeckSlot(index: 9, title: "Lock", actionType: .systemToggle, target: "lockScreen", iconName: "lock.fill")
        ]
        return NotchDeckConfig(gridColumns: 5, gridRows: 2, slots: defaultSlots, appearance: GlassAppearanceSettings())
    }
}
