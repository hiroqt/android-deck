import SwiftUI

public struct ExpandedDeckView: View {
    @ObservedObject var phoneDeckService = PhoneDeckService.shared
    public let onCollapse: () -> Void
    public let onOpenSettings: () -> Void
    public let onSelectSlotToEdit: (PhoneDeckSlot) -> Void
    public var onEditSlot: (DeckSlot) -> Void = { _ in }

    public init(
        phoneDeckService: PhoneDeckService = .shared,
        initialTab: Int = 0,
        onCollapse: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onSelectSlotToEdit: @escaping (PhoneDeckSlot) -> Void
    ) {
        self.phoneDeckService = phoneDeckService
        self._selectedTab = State(initialValue: initialTab)
        self.onCollapse = onCollapse
        self.onOpenSettings = onOpenSettings
        self.onSelectSlotToEdit = onSelectSlotToEdit
        self.onEditSlot = { _ in }
    }

    public init(
        configManager: ConfigManager,
        onCollapse: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onEditSlot: @escaping (DeckSlot) -> Void
    ) {
        self.phoneDeckService = .shared
        self.onCollapse = onCollapse
        self.onOpenSettings = onOpenSettings
        self.onSelectSlotToEdit = { _ in }
        self.onEditSlot = onEditSlot
    }

    public init(
        configManager: ConfigManager,
        isEditing: Bool = false,
        onCollapse: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onEditSlot: @escaping (DeckSlot) -> Void
    ) {
        self.phoneDeckService = .shared
        self.onCollapse = onCollapse
        self.onOpenSettings = onOpenSettings
        self.onSelectSlotToEdit = { _ in }
        self.onEditSlot = onEditSlot
    }

    @State public var selectedTab: Int = 0

    public var body: some View {
        VStack(spacing: 6) {
            // Header bar
            HStack(spacing: 8) {
                // Title
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyan)

                    Text("NOTCH DECK")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.85))
                }

                Spacer()

                // Tab Switcher (Apps vs Control Panel)
                HStack(spacing: 2) {
                    Button(action: { withAnimation { selectedTab = 0 } }) {
                        Text("Apps")
                            .font(.system(size: 10, weight: selectedTab == 0 ? .bold : .medium))
                            .foregroundColor(selectedTab == 0 ? .white : Color.white.opacity(0.6))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(selectedTab == 0 ? Color.white.opacity(0.18) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: { withAnimation { selectedTab = 1 } }) {
                        Text("Controls")
                            .font(.system(size: 10, weight: selectedTab == 1 ? .bold : .medium))
                            .foregroundColor(selectedTab == 1 ? .white : Color.white.opacity(0.6))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(selectedTab == 1 ? Color.white.opacity(0.18) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(2)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                )

                Spacer()

                // Connected Device Badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(phoneDeckService.isDeviceConnected ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                        .shadow(color: phoneDeckService.isDeviceConnected ? Color.green.opacity(0.8) : Color.clear, radius: 3)

                    Text(deviceStatusText)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(phoneDeckService.isDeviceConnected ? .white : Color.white.opacity(0.65))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                )

                Spacer()

                // Action Controls
                HStack(spacing: 10) {
                    // Reset to defaults
                    Button(action: {
                        withAnimation { phoneDeckService.resetDefaults() }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Reset slots to defaults")

                    // Open Preferences
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Preferences")

                    // Collapse button
                    Button(action: onCollapse) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Collapse")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Content: Tab 0 (6 Apps Grid) vs Tab 1 (Notch Control Panel)
            if selectedTab == 0 {
                LazyVGrid(
                    columns: [
                        GridItem(.fixed(132), spacing: 12),
                        GridItem(.fixed(132), spacing: 12),
                        GridItem(.fixed(132), spacing: 12)
                    ],
                    spacing: 10
                ) {
                    ForEach(displaySlots) { slot in
                        DeckSlotCardView(
                            slot: slot,
                            onEdit: {
                                onSelectSlotToEdit(slot)
                            },
                            onRemove: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.72)) {
                                    phoneDeckService.clearSlot(index: slot.index)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            } else {
                NotchControlPanelView()
                    .transition(.opacity)
            }

            Spacer(minLength: 0)

            // Page Indicator Dots
            HStack(spacing: 6) {
                Circle()
                    .fill(selectedTab == 0 ? Color.cyan : Color.white.opacity(0.25))
                    .frame(width: selectedTab == 0 ? 7 : 5, height: selectedTab == 0 ? 7 : 5)
                    .onTapGesture { withAnimation { selectedTab = 0 } }

                Circle()
                    .fill(selectedTab == 1 ? Color.cyan : Color.white.opacity(0.25))
                    .frame(width: selectedTab == 1 ? 7 : 5, height: selectedTab == 1 ? 7 : 5)
                    .onTapGesture { withAnimation { selectedTab = 1 } }
            }
            .padding(.bottom, 6)
        }
        .frame(width: 480, height: 224)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < -30 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTab = 1
                        }
                    } else if value.translation.width > 30 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTab = 0
                        }
                    }
                }
        )
    }

    private var deviceStatusText: String {
        if phoneDeckService.isDeviceConnected {
            if let name = phoneDeckService.connectedDeviceName, !name.isEmpty {
                return "📱 \(name)"
            }
            return "📱 Phone Connected"
        } else {
            return "⚪ Waiting for Phone..."
        }
    }

    private var displaySlots: [PhoneDeckSlot] {
        var result = phoneDeckService.slots
        while result.count < 6 {
            let idx = result.count
            result.append(PhoneDeckSlot(id: "app-\(idx + 1)", index: idx, label: "", bundleId: ""))
        }
        return Array(result.prefix(6))
    }
}
