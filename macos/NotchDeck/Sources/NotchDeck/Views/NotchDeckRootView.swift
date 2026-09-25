import SwiftUI

public struct NotchDeckRootView: View {
    @ObservedObject var configManager: ConfigManager
    @ObservedObject var phoneDeckService = PhoneDeckService.shared
    @Binding var isExpanded: Bool
    public let hasPhysicalNotch: Bool
    public let onOpenSettings: () -> Void
    public let onSelectPhoneSlot: (PhoneDeckSlot) -> Void
    public let onEditSlot: (DeckSlot) -> Void

    public init(
        configManager: ConfigManager = .shared,
        phoneDeckService: PhoneDeckService = .shared,
        isExpanded: Binding<Bool>,
        hasPhysicalNotch: Bool = false,
        onOpenSettings: @escaping () -> Void = {},
        onSelectPhoneSlot: @escaping (PhoneDeckSlot) -> Void = { _ in },
        onEditSlot: @escaping (DeckSlot) -> Void = { _ in }
    ) {
        self.configManager = configManager
        self.phoneDeckService = phoneDeckService
        self._isExpanded = isExpanded
        self.hasPhysicalNotch = hasPhysicalNotch
        self.onOpenSettings = onOpenSettings
        self.onSelectPhoneSlot = onSelectPhoneSlot
        self.onEditSlot = onEditSlot
    }

    public var body: some View {
        ZStack(alignment: .top) {
            LiquidGlassBackground(
                cornerRadius: isExpanded ? 24 : (hasPhysicalNotch ? 12 : 16),
                specularIntensity: configManager.config.appearance.specularIntensity,
                isExpanded: isExpanded
            )

            if isExpanded {
                ExpandedDeckView(
                    phoneDeckService: phoneDeckService,
                    onCollapse: {
                        withAnimation(.interactiveSpring(response: 0.36, dampingFraction: 0.74, blendDuration: 0.12)) {
                            isExpanded = false
                        }
                    },
                    onOpenSettings: onOpenSettings,
                    onSelectSlotToEdit: onSelectPhoneSlot
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.94, anchor: .top)),
                    removal: .opacity
                ))
            } else {
                CollapsedNotchView(
                    phoneDeckService: phoneDeckService,
                    hasPhysicalNotch: hasPhysicalNotch,
                    onExpand: {
                        withAnimation(.interactiveSpring(response: 0.36, dampingFraction: 0.74, blendDuration: 0.12)) {
                            isExpanded = true
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .frame(
            width: isExpanded ? 480 : 180,
            height: isExpanded ? 224 : 32
        )
        .animation(.interactiveSpring(response: 0.36, dampingFraction: 0.74, blendDuration: 0.12), value: isExpanded)
    }
}
