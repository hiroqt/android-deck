import SwiftUI

public struct NotchDeckRootView: View {
    @ObservedObject var configManager: ConfigManager
    @Binding var isExpanded: Bool
    public let hasPhysicalNotch: Bool
    public let onOpenSettings: () -> Void
    public let onEditSlot: (DeckSlot) -> Void

    public init(
        configManager: ConfigManager = .shared,
        isExpanded: Binding<Bool>,
        hasPhysicalNotch: Bool = false,
        onOpenSettings: @escaping () -> Void = {},
        onEditSlot: @escaping (DeckSlot) -> Void = { _ in }
    ) {
        self.configManager = configManager
        self._isExpanded = isExpanded
        self.hasPhysicalNotch = hasPhysicalNotch
        self.onOpenSettings = onOpenSettings
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
                    configManager: configManager,
                    onCollapse: {
                        withAnimation(.interactiveSpring(response: 0.36, dampingFraction: 0.74, blendDuration: 0.12)) {
                            isExpanded = false
                        }
                    },
                    onOpenSettings: onOpenSettings,
                    onEditSlot: onEditSlot
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.94, anchor: .top)),
                    removal: .opacity
                ))
            } else {
                CollapsedNotchView(
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
            width: isExpanded ? 520 : 180,
            height: isExpanded ? 172 : 32
        )
        .animation(.interactiveSpring(response: 0.36, dampingFraction: 0.74, blendDuration: 0.12), value: isExpanded)
    }
}
