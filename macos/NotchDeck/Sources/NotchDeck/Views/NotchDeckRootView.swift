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

    private let shadowMargin: CGFloat = NotchPanel.shadowMargin

    public var body: some View {
        VStack(spacing: 0) {
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
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.76, blendDuration: 0.1)) {
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
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.76, blendDuration: 0.1)) {
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
            .contentShape(Rectangle())
            .onTapGesture {
                if !isExpanded {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.76, blendDuration: 0.1)) {
                        isExpanded = true
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, shadowMargin)
        .frame(
            width: (isExpanded ? 480 : 180) + shadowMargin * 2,
            height: (isExpanded ? 224 : 32) + shadowMargin
        )
        .animation(.spring(response: 0.38, dampingFraction: 0.76, blendDuration: 0.1), value: isExpanded)
    }
}
