import Foundation

public struct ScreenGeometry: Equatable {
    public var screenWidth: CGFloat
    public var screenHeight: CGFloat
    public var topSafeAreaInset: CGFloat
    public var physicalNotchWidth: CGFloat
    public var hasPhysicalNotch: Bool

    public init(
        screenWidth: CGFloat,
        screenHeight: CGFloat,
        topSafeAreaInset: CGFloat,
        physicalNotchWidth: CGFloat? = nil
    ) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.topSafeAreaInset = topSafeAreaInset
        self.hasPhysicalNotch = topSafeAreaInset > 24.0
        if let customWidth = physicalNotchWidth {
            self.physicalNotchWidth = customWidth
        } else {
            // Default physical notch width across M-series Macs:
            // 14" MBP / MacBook Air: ~179-180pt
            // 16" MBP: ~210pt
            self.physicalNotchWidth = (screenWidth >= 1700 && topSafeAreaInset > 24.0) ? 210.0 : 180.0
        }
    }

    public var notchCollapsedSize: CGSize {
        return collapsedSize(for: .top)
    }

    public var notchExpandedSize: CGSize {
        return expandedSize(for: .top)
    }

    public static func physicalCollapsedWidth(physicalNotchWidth: CGFloat) -> CGFloat {
        return max(360, physicalNotchWidth + 180)
    }

    public static func physicalCollapsedHeight(topSafeAreaInset: CGFloat) -> CGFloat {
        return max(44, topSafeAreaInset + 12)
    }

    public func collapsedSize(for edge: NotchEdge) -> CGSize {
        if edge.isVertical {
            return CGSize(width: 48, height: 116)
        } else {
            if hasPhysicalNotch {
                // To ensure the notch is completely unobstructed on any M-series Mac:
                // 1. Width extends generously beyond the camera cutout on left and right (giving ~80-95pt wings)
                // 2. Height extends 12pt below the menu bar into display space (sleek tactile bottom chin)
                let width = Self.physicalCollapsedWidth(physicalNotchWidth: physicalNotchWidth)
                let height = Self.physicalCollapsedHeight(topSafeAreaInset: topSafeAreaInset)
                return CGSize(width: width, height: height)
            } else {
                return CGSize(width: 184, height: 34)
            }
        }
    }

    public func expandedSize(for edge: NotchEdge) -> CGSize {
        if edge.isVertical {
            return CGSize(width: 280, height: 380)
        } else {
            if hasPhysicalNotch {
                return CGSize(width: 480, height: 248)
            } else {
                return CGSize(width: 480, height: 224)
            }
        }
    }

    /// Computes the exact screen frame for the NotchPanel given edge, expansion state, and vertical position ratio.
    public func panelFrame(
        for edge: NotchEdge,
        isExpanded: Bool,
        sidePositionRatio: CGFloat = 0.5,
        shadowMargin: CGFloat = 24.0,
        screenRect: CGRect? = nil
    ) -> CGRect {
        let baseScreen = screenRect ?? CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        let contentSize = isExpanded ? expandedSize(for: edge) : collapsedSize(for: edge)

        switch edge {
        case .top:
            let panelWidth = contentSize.width + shadowMargin * 2
            let panelHeight = contentSize.height + shadowMargin
            let panelX = baseScreen.midX - panelWidth / 2
            let panelY = baseScreen.maxY - panelHeight
            return CGRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)

        case .right:
            let panelWidth = contentSize.width + shadowMargin
            let panelHeight = contentSize.height + shadowMargin * 2
            let panelX = baseScreen.maxX - panelWidth
            let clampedRatio = max(0.05, min(0.95, sidePositionRatio))
            let availableTravel = max(10, baseScreen.height - panelHeight - 60)
            let panelY = baseScreen.minY + 30 + availableTravel * clampedRatio
            return CGRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)

        case .left:
            let panelWidth = contentSize.width + shadowMargin
            let panelHeight = contentSize.height + shadowMargin * 2
            let panelX = baseScreen.minX
            let clampedRatio = max(0.05, min(0.95, sidePositionRatio))
            let availableTravel = max(10, baseScreen.height - panelHeight - 60)
            let panelY = baseScreen.minY + 30 + availableTravel * clampedRatio
            return CGRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)
        }
    }

    /// Determines whether the mouse point is within a docking zone (near top, left, or right edge).
    /// Returns the target edge if within `dockZoneThreshold`, or nil if in free-floating screen space.
    public static func dockingEdge(
        for point: CGPoint,
        screenFrame: CGRect,
        currentEdge: NotchEdge,
        dockZoneThreshold: CGFloat = 110.0
    ) -> NotchEdge? {
        let distLeft = abs(point.x - screenFrame.minX)
        let distRight = abs(screenFrame.maxX - point.x)
        let distTop = abs(screenFrame.maxY - point.y)

        // If outside proximity of any docking boundary, it's free floating
        if distLeft > dockZoneThreshold && distRight > dockZoneThreshold && distTop > dockZoneThreshold {
            return nil
        }

        return targetEdge(for: point, screenFrame: screenFrame, currentEdge: currentEdge)
    }

    /// Determines the closest edge to a mouse drop point with a hysteresis bias for stability.
    public static func targetEdge(
        for point: CGPoint,
        screenFrame: CGRect,
        currentEdge: NotchEdge
    ) -> NotchEdge {
        let distLeft = abs(point.x - screenFrame.minX)
        let distRight = abs(screenFrame.maxX - point.x)
        let distTop = abs(screenFrame.maxY - point.y)

        // Hysteresis bias: gives the current edge a 70pt advantage to prevent accidental flipping during sliding
        let bias: CGFloat = 70.0
        let adjustedLeft = currentEdge == .left ? distLeft - bias : distLeft
        let adjustedRight = currentEdge == .right ? distRight - bias : distRight
        let adjustedTop = currentEdge == .top ? distTop - bias : distTop

        let minDist = min(adjustedLeft, adjustedRight, adjustedTop)
        if minDist == adjustedTop {
            return .top
        } else if minDist == adjustedRight {
            return .right
        } else {
            return .left
        }
    }
}
