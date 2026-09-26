import SwiftUI

public struct NotchDeckRootView: View {
    @ObservedObject var configManager: ConfigManager
    @ObservedObject var phoneDeckService = PhoneDeckService.shared
    @Binding var isExpanded: Bool
    public let edge: NotchEdge
    public let hasPhysicalNotch: Bool
    public var physicalNotchWidth: CGFloat = 180
    public var topSafeAreaInset: CGFloat = 32
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
        physicalNotchWidth: CGFloat = 180,
        topSafeAreaInset: CGFloat = 32,
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
        self.physicalNotchWidth = physicalNotchWidth
        self.topSafeAreaInset = topSafeAreaInset
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
            if isExpanded {
                return 480
            } else {
                return hasPhysicalNotch ? ScreenGeometry.physicalCollapsedWidth(physicalNotchWidth: physicalNotchWidth) : 184
            }
        }
    }

    private var contentHeight: CGFloat {
        if isDetached {
            return 40
        }
        if edge.isVertical {
            return isExpanded ? 380 : 116
        } else {
            if isExpanded {
                return hasPhysicalNotch ? 248 : 224
            } else {
                let baseHeight = hasPhysicalNotch ? ScreenGeometry.physicalCollapsedHeight(topSafeAreaInset: topSafeAreaInset) : 34
                return baseHeight + stretchDistance
            }
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


    private var notchCornerRadius: CGFloat {
        if isDetached {
            return 20
        }
        if isExpanded {
            return 24
        }
        return (hasPhysicalNotch && edge == .top) ? 14 : 18
    }

    private var shape: LiquidPullShape {
        LiquidPullShape(
            edge: edge,
            stretchDistance: stretchDistance,
            lateralOffset: lateralOffset,
            isDetached: isDetached,
            cornerRadius: notchCornerRadius
        )
    }

    public var body: some View {
        GeometryReader { proxy in
            let effectiveWindowSize = CGSize(
                width: proxy.size.width > 0 ? proxy.size.width : totalContainerWidth,
                height: proxy.size.height > 0 ? proxy.size.height : totalContainerHeight
            )
            let notchSize = currentNotchSize(in: effectiveWindowSize)

            ZStack(alignment: notchAlignment) {
                mainNotchContainer(size: notchSize)
                    .frame(width: notchSize.width, height: notchSize.height)
            }
            .frame(width: effectiveWindowSize.width, height: effectiveWindowSize.height, alignment: notchAlignment)
            .animation(nil, value: effectiveWindowSize)
        }
    }

    private var notchAlignment: Alignment {
        if isDetached { return .center }
        switch edge {
        case .top: return .top
        case .right: return .trailing
        case .left: return .leading
        }
    }

    private func currentNotchSize(in windowSize: CGSize) -> CGSize {
        if isDetached {
            return CGSize(
                width: max(0, windowSize.width - shadowMargin * 2),
                height: max(0, windowSize.height - shadowMargin * 2)
            )
        }
        switch edge {
        case .top:
            return CGSize(
                width: max(0, windowSize.width - shadowMargin * 2),
                height: max(0, windowSize.height - shadowMargin)
            )
        case .right, .left:
            return CGSize(
                width: max(0, windowSize.width - shadowMargin),
                height: max(0, windowSize.height - shadowMargin * 2)
            )
        }
    }

    private func mainNotchContainer(size: CGSize) -> some View {
        ZStack(alignment: containerAlignment) {
            LiquidGlassBackground(
                edge: edge,
                cornerRadius: notchCornerRadius,
                curlRadius: (hasPhysicalNotch && edge == .top && !isExpanded) ? 12 : 14,
                specularIntensity: configManager.config.appearance.specularIntensity,
                isExpanded: isExpanded,
                stretchDistance: stretchDistance,
                lateralOffset: lateralOffset,
                isDetached: isDetached,
                glassTintOpacity: configManager.config.appearance.glassTintOpacity,
                ambientBacklightEnabled: configManager.config.appearance.ambientBacklightEnabled
            )

            Group {
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
                        hasPhysicalNotch: hasPhysicalNotch,
                        onCollapse: {
                            isExpanded = false
                        },
                        onOpenSettings: onOpenSettings,
                        onSelectSlotToEdit: onSelectPhoneSlot
                    )
                    .transition(.opacity)
                } else {
                    CollapsedNotchView(
                        phoneDeckService: phoneDeckService,
                        edge: edge,
                        hasPhysicalNotch: hasPhysicalNotch,
                        notchWidth: hasPhysicalNotch ? ScreenGeometry.physicalCollapsedWidth(physicalNotchWidth: physicalNotchWidth) : 184,
                        notchHeight: hasPhysicalNotch ? ScreenGeometry.physicalCollapsedHeight(topSafeAreaInset: topSafeAreaInset) : 34,
                        physicalNotchWidth: physicalNotchWidth,
                        onExpand: {
                            isExpanded = true
                        }
                    )
                    .transition(.opacity)
                }
            }
            .clipShape(shape)
        }
        .frame(width: size.width, height: size.height)
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
