import SwiftUI

public struct ExpandedDeckView: View {
    @ObservedObject var configManager: ConfigManager
    public let onCollapse: () -> Void
    public let onOpenSettings: () -> Void
    public let onEditSlot: (DeckSlot) -> Void

    @State private var isEditing = false

    public init(
        configManager: ConfigManager,
        onCollapse: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onEditSlot: @escaping (DeckSlot) -> Void
    ) {
        self.configManager = configManager
        self._isEditing = State(initialValue: false)
        self.onCollapse = onCollapse
        self.onOpenSettings = onOpenSettings
        self.onEditSlot = onEditSlot
    }

    public init(
        configManager: ConfigManager,
        isEditing: Bool,
        onCollapse: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onEditSlot: @escaping (DeckSlot) -> Void
    ) {
        self.configManager = configManager
        self._isEditing = State(initialValue: isEditing)
        self.onCollapse = onCollapse
        self.onOpenSettings = onOpenSettings
        self.onEditSlot = onEditSlot
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header bar
            HStack {
                // Status / Brand
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("NOTCH DECK")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.8))
                }

                Spacer()

                // Edit mode toggle
                Button(action: { withAnimation { isEditing.toggle() } }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                        .font(.system(size: 15))
                        .foregroundColor(isEditing ? .green : .white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(isEditing ? "Done editing" : "Edit slots")

                // Open Settings
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Settings")

                // Collapse button
                Button(action: onCollapse) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Collapse")
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Slot Matrix Grid
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(68), spacing: 8), count: max(1, configManager.config.gridColumns)), spacing: 10) {
                ForEach(configManager.config.slots) { slot in
                    DeckSlotTileView(
                        slot: slot,
                        isEditing: isEditing,
                        onSelect: {
                            ActionExecutionService.shared.execute(slot: slot)
                        },
                        onEdit: {
                            onEditSlot(slot)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: 520, height: 172)
    }
}
