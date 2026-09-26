import SwiftUI

public struct ExpandedDeckView: View {
    @ObservedObject var phoneDeckService = PhoneDeckService.shared
    public let edge: NotchEdge
    public let hasPhysicalNotch: Bool
    public let onCollapse: () -> Void
    public let onOpenSettings: () -> Void
    public let onSelectSlotToEdit: (PhoneDeckSlot) -> Void
    public var onEditSlot: (DeckSlot) -> Void = { _ in }

    public init(
        phoneDeckService: PhoneDeckService = .shared,
        edge: NotchEdge = .top,
        hasPhysicalNotch: Bool = false,
        initialTab: Int = 0,
        onCollapse: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onSelectSlotToEdit: @escaping (PhoneDeckSlot) -> Void
    ) {
        self.phoneDeckService = phoneDeckService
        self.edge = edge
        self.hasPhysicalNotch = hasPhysicalNotch
        self._selectedTab = State(initialValue: initialTab)
        self.onCollapse = onCollapse
        self.onOpenSettings = onOpenSettings
        self.onSelectSlotToEdit = onSelectSlotToEdit
        self.onEditSlot = { _ in }
    }

    public init(
        configManager: ConfigManager,
        edge: NotchEdge = .top,
        hasPhysicalNotch: Bool = false,
        onCollapse: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onEditSlot: @escaping (DeckSlot) -> Void
    ) {
        self.phoneDeckService = .shared
        self.edge = edge
        self.hasPhysicalNotch = hasPhysicalNotch
        self.onCollapse = onCollapse
        self.onOpenSettings = onOpenSettings
        self.onSelectSlotToEdit = { _ in }
        self.onEditSlot = onEditSlot
    }

    public init(
        configManager: ConfigManager,
        isEditing: Bool = false,
        edge: NotchEdge = .top,
        hasPhysicalNotch: Bool = false,
        onCollapse: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onEditSlot: @escaping (DeckSlot) -> Void
    ) {
        self.phoneDeckService = .shared
        self.edge = edge
        self.hasPhysicalNotch = hasPhysicalNotch
        self.onCollapse = onCollapse
        self.onOpenSettings = onOpenSettings
        self.onSelectSlotToEdit = { _ in }
        self.onEditSlot = onEditSlot
    }

    @State public var selectedTab: Int = 0

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            if edge.isVertical {
                verticalHeader
                Spacer().frame(height: 14)
            } else {
                horizontalHeader
                Spacer().frame(height: 12)
            }

            // App Slots Grid
            if edge.isVertical {
                LazyVGrid(
                    columns: [
                        GridItem(.fixed(122), spacing: 10),
                        GridItem(.fixed(122), spacing: 10)
                    ],
                    spacing: 12
                ) {
                    ForEach(displaySlots) { slot in
                        DeckSlotCardView(
                            slot: slot,
                            cardWidth: 122,
                            cardHeight: 78,
                            onEdit: {
                                onSelectSlotToEdit(slot)
                            },
                            onRemove: {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    phoneDeckService.clearSlot(index: slot.index)
                                }
                            }
                        )
                        .id("\(slot.id)-\(slot.bundleId)-\(slot.label)")
                    }
                }
                .padding(.horizontal, 13)
            } else {
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
                            cardWidth: 132,
                            cardHeight: 74,
                            onEdit: {
                                onSelectSlotToEdit(slot)
                            },
                            onRemove: {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    phoneDeckService.clearSlot(index: slot.index)
                                }
                            }
                        )
                        .id("\(slot.id)-\(slot.bundleId)-\(slot.label)")
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 0)
        }
        .frame(
            width: edge.isVertical ? 280 : 480,
            height: edge.isVertical ? 380 : (hasPhysicalNotch ? 248 : 224)
        )
    }

    // MARK: - Dedicated Vertical Header
    private var verticalHeader: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyan)

                    Text("NOTCH DECK")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.85))
                }

                Spacer()

                HStack(spacing: 10) {
                    presetQuickMenu

                    Button(action: {
                        withAnimation { phoneDeckService.resetDefaults() }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Reset slots to defaults")

                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Preferences")

                    Button(action: onCollapse) {
                        Image(systemName: collapseChevronIcon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Collapse")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)

            // Device Status Badge (Full Width Centered)
            deviceStatusBadge
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Horizontal Top Header
    private var horizontalHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                // Title with Deck Icon (Left Wing)
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyan)

                    Text("NOTCH DECK")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.85))
                }
                .padding(.leading, 20)

                Spacer(minLength: 20)

                if !hasPhysicalNotch {
                    // Connected Device Badge (Centered only on non-notch Macs)
                    deviceStatusBadge

                    Spacer(minLength: 20)
                } else {
                    // Physical Camera Hardware Clearance in the top row
                    Spacer()
                        .frame(width: 196)
                }

                // Action Controls (Right Wing)
                HStack(spacing: 10) {
                    presetQuickMenu

                    Button(action: {
                        withAnimation { phoneDeckService.resetDefaults() }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Reset slots to defaults")

                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Preferences")

                    Button(action: onCollapse) {
                        Image(systemName: collapseChevronIcon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Collapse")
                }
                .padding(.trailing, 20)
            }
            .padding(.top, 16)

            if hasPhysicalNotch {
                // On Macs with a physical camera notch, place deviceStatusBadge centered
                // right BELOW the camera notch so it is unobstructed and 100% visible!
                deviceStatusBadge
                    .padding(.top, 2)
            }
        }
    }

    private var presetQuickMenu: some View {
        Menu {
            Section("Deck Presets") {
                ForEach(phoneDeckService.presets) { preset in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            phoneDeckService.applyPreset(id: preset.id)
                        }
                    }) {
                        if phoneDeckService.activePresetId == preset.id {
                            Label(preset.name, systemImage: "checkmark")
                        } else {
                            Text(preset.name)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "slider.horizontal.2.square")
                .font(.system(size: 11.5))
                .foregroundColor(Color.white.opacity(0.7))
        }
        .menuStyle(.borderlessButton)
        .help("Switch Deck Preset")
    }

    // MARK: - Device Status Badge (Icon + Typography, Zero Emojis)
    private var deviceStatusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(phoneDeckService.isDeviceConnected ? Color.green : Color.orange)
                .frame(width: 6, height: 6)
                .shadow(
                    color: (phoneDeckService.isDeviceConnected ? Color.green : Color.orange).opacity(0.8),
                    radius: 3
                )

            // Phone Vector Icon (No Emoji)
            Image(systemName: phoneDeckService.isDeviceConnected ? "iphone.gen3" : "iphone.slash")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(phoneDeckService.isDeviceConnected ? Color.white.opacity(0.9) : Color.white.opacity(0.55))

            // Status Text
            Text(connectedDeviceNameText)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .foregroundColor(phoneDeckService.isDeviceConnected ? .white : Color.white.opacity(0.7))
                .lineLimit(1)

            // Battery Level if available
            if phoneDeckService.isDeviceConnected, let battery = phoneDeckService.batteryLevel {
                HStack(spacing: 2) {
                    if phoneDeckService.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundColor(.green)
                    }
                    Text("\(battery)%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.leading, 2)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
    }

    private var connectedDeviceNameText: String {
        if phoneDeckService.isDeviceConnected {
            if let name = phoneDeckService.connectedDeviceName, !name.isEmpty {
                return name
            }
            return "Phone Connected"
        } else {
            return "Waiting..."
        }
    }

    private var collapseChevronIcon: String {
        switch edge {
        case .top: return "chevron.up"
        case .right: return "chevron.right"
        case .left: return "chevron.left"
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
