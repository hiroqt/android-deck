import SwiftUI

public struct NotchDeckRootView: View {
    @ObservedObject var configManager: ConfigManager
    @ObservedObject var phoneDeckService = PhoneDeckService.shared
    @Binding var isExpanded: Bool
    public let edge: NotchEdge
    public let hasPhysicalNotch: Bool
    public var stretchDistance: CGFloat = 0.0
    public var lateralOffset: CGFloat = 0.0
    public var isDetached: Bool = false
    public var dragTargetEdge: NotchEdge? = nil
    public let onOpenSettings: () -> Void
    public let onSelectPhoneSlot: (PhoneDeckSlot) -> Void
    public let onEditSlot: (DeckSlot) -> Void
    public var onBeginDrag: () -> Void = {}
    public var onUpdateDrag: () -> Void = {}
    public var onEndDrag: () -> Void = {}

    @State private var isDraggingGesture: Bool = false

    public init(
        configManager: ConfigManager = .shared,
        phoneDeckService: PhoneDeckService = .shared,
        isExpanded: Binding<Bool>,
        edge: NotchEdge = .top,
        hasPhysicalNotch: Bool = false,
        stretchDistance: CGFloat = 0.0,
        lateralOffset: CGFloat = 0.0,
        isDetached: Bool = false,
        dragTargetEdge: NotchEdge? = nil,
        onOpenSettings: @escaping () -> Void = {},
        onSelectPhoneSlot: @escaping (PhoneDeckSlot) -> Void = { _ in },
        onEditSlot: @escaping (DeckSlot) -> Void = { _ in },
        onBeginDrag: @escaping () -> Void = {},
        onUpdateDrag: @escaping () -> Void = {},
        onEndDrag: @escaping () -> Void = {}
    ) {
        self.configManager = configManager
        self.phoneDeckService = phoneDeckService
        self._isExpanded = isExpanded
        self.edge = edge
        self.hasPhysicalNotch = hasPhysicalNotch
        self.stretchDistance = stretchDistance
        self.lateralOffset = lateralOffset
        self.isDetached = isDetached
        self.dragTargetEdge = dragTargetEdge
        self.onOpenSettings = onOpenSettings
        self.onSelectPhoneSlot = onSelectPhoneSlot
        self.onEditSlot = onEditSlot
        self.onBeginDrag = onBeginDrag
        self.onUpdateDrag = onUpdateDrag
        self.onEndDrag = onEndDrag
    }

    private let shadowMargin: CGFloat = NotchPanel.shadowMargin

    private var isDraggingOrStretching: Bool {
        isDetached || stretchDistance > 1.0
    }

    private var contentWidth: CGFloat {
        if isDetached {
            return 76
        }
        if edge.isVertical {
            return (isExpanded ? 280 : 48) + stretchDistance
        } else {
            return isExpanded ? 480 : 180
        }
    }

    private var contentHeight: CGFloat {
        if isDetached {
            return 40
        }
        if edge.isVertical {
            return isExpanded ? 380 : 116
        } else {
            return (isExpanded ? 224 : 32) + stretchDistance
        }
    }

    private var totalContainerWidth: CGFloat {
        if isDetached {
            return contentWidth + shadowMargin * 2
        }
        if edge.isVertical {
            return contentWidth + shadowMargin
        } else {
            return contentWidth + shadowMargin * 2
        }
    }

    private var totalContainerHeight: CGFloat {
        if isDetached {
            return contentHeight + shadowMargin * 2
        }
        if edge.isVertical {
            return contentHeight + shadowMargin * 2
        } else {
            return contentHeight + shadowMargin
        }
    }

    private var rootAlignment: Alignment {
        if isDetached { return .center }
        switch edge {
        case .top: return .top
        case .right: return .trailing
        case .left: return .leading
        }
    }

    private var containerPadding: EdgeInsets {
        if isDetached {
            return EdgeInsets(top: shadowMargin, leading: shadowMargin, bottom: shadowMargin, trailing: shadowMargin)
        }
        switch edge {
        case .top:
            return EdgeInsets(top: 0, leading: shadowMargin, bottom: shadowMargin, trailing: shadowMargin)
        case .right:
            return EdgeInsets(top: shadowMargin, leading: shadowMargin, bottom: shadowMargin, trailing: 0)
        case .left:
            return EdgeInsets(top: shadowMargin, leading: 0, bottom: shadowMargin, trailing: shadowMargin)
        }
    }

    public var body: some View {
        ZStack(alignment: rootAlignment) {
            mainNotchContainer
                .padding(containerPadding)
        }
        .frame(width: totalContainerWidth, height: totalContainerHeight)
        .animation(.easeInOut(duration: 0.26), value: isExpanded)
        .animation(.easeInOut(duration: 0.26), value: edge)
        .animation(.easeInOut(duration: 0.26), value: isDetached)
    }

    private var mainNotchContainer: some View {
        ZStack(alignment: containerAlignment) {
            LiquidGlassBackground(
                edge: edge,
                cornerRadius: isDetached ? 20 : (isExpanded ? 24 : (hasPhysicalNotch && edge == .top ? 12 : 18)),
                curlRadius: (hasPhysicalNotch && edge == .top && !isExpanded) ? 0 : 14,
                specularIntensity: configManager.config.appearance.specularIntensity,
                isExpanded: isExpanded,
                stretchDistance: stretchDistance,
                lateralOffset: lateralOffset,
                isDetached: isDetached,
                glassTintOpacity: configManager.config.appearance.glassTintOpacity,
                ambientBacklightEnabled: configManager.config.appearance.ambientBacklightEnabled
            )

            if isDraggingOrStretching {
                // THE LIQUID PART ONLY (not the whole deck notch!)
                LiquidDropletContentView(
                    edge: edge,
                    phoneDeckService: phoneDeckService,
                    isDetached: isDetached,
                    dragTargetEdge: dragTargetEdge
                )
                .frame(
                    width: isDetached ? 76 : (edge.isVertical ? 44 : 76),
                    height: isDetached ? 40 : (edge.isVertical ? 60 : 32)
                )
                .offset(dropletContentOffset)
                .transition(.opacity)
            } else if isExpanded {
                ExpandedDeckView(
                    phoneDeckService: phoneDeckService,
                    edge: edge,
                    onCollapse: {
                        withAnimation(.easeInOut(duration: 0.26)) {
                            isExpanded = false
                        }
                    },
                    onOpenSettings: onOpenSettings,
                    onSelectSlotToEdit: onSelectPhoneSlot
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: contentAnchor)),
                    removal: .opacity
                ))
            } else {
                CollapsedNotchView(
                    phoneDeckService: phoneDeckService,
                    edge: edge,
                    hasPhysicalNotch: hasPhysicalNotch,
                    onExpand: {
                        withAnimation(.easeInOut(duration: 0.26)) {
                            isExpanded = true
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .frame(width: contentWidth, height: contentHeight)
        .simultaneousGesture(
            DragGesture(minimumDistance: 4)
                .onChanged { _ in
                    if !isDraggingGesture {
                        isDraggingGesture = true
                        onBeginDrag()
                    }
                    onUpdateDrag()
                }
                .onEnded { _ in
                    isDraggingGesture = false
                    onEndDrag()
                }
        )
    }

    private var containerAlignment: Alignment {
        if isDetached { return .center }
        switch edge {
        case .top: return .top
        case .right: return .trailing
        case .left: return .leading
        }
    }

    private var dropletContentOffset: CGSize {
        if isDetached {
            return .zero
        }
        switch edge {
        case .top:
            return CGSize(width: lateralOffset * 0.35, height: stretchDistance)
        case .right:
            return CGSize(width: -stretchDistance, height: lateralOffset * 0.35)
        case .left:
            return CGSize(width: stretchDistance, height: lateralOffset * 0.35)
        }
    }

    private var contentAnchor: UnitPoint {
        switch edge {
        case .top: return .top
        case .right: return .trailing
        case .left: return .leading
        }
    }
}
