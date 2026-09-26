import Foundation

public struct ScreenGeometry: Equatable {
    public var screenWidth: CGFloat
    public var screenHeight: CGFloat
    public var topSafeAreaInset: CGFloat
    public var hasPhysicalNotch: Bool

    public init(screenWidth: CGFloat, screenHeight: CGFloat, topSafeAreaInset: CGFloat) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.topSafeAreaInset = topSafeAreaInset
        self.hasPhysicalNotch = topSafeAreaInset > 24.0
    }

    public var notchCollapsedSize: CGSize {
        return collapsedSize(for: .top)
    }

    public var notchExpandedSize: CGSize {
        return expandedSize(for: .top)
    }

    public func collapsedSize(for edge: NotchEdge) -> CGSize {
        if edge.isVertical {
            return CGSize(width: 48, height: 116)
        } else {
            if hasPhysicalNotch {
                return CGSize(width: 180, height: max(32, topSafeAreaInset))
            } else {
                return CGSize(width: 180, height: 34)
            }
        }
    }

    public func expandedSize(for edge: NotchEdge) -> CGSize {
        if edge.isVertical {
            return CGSize(width: 280, height: 380)
        } else {
            return CGSize(width: 480, height: 224)
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
