import SwiftUI

/// An elastic liquid pull shape that stretches organically from the screen bezel.
///
/// While being pulled, it renders a fluid liquid neck with a narrow waist (metaball tendon)
/// connecting the bezel anchor to a floating bulb. When detached or resting, it transitions
/// cleanly between the bezel-docked shape and a compact floating droplet.
public struct LiquidPullShape: Shape, InsettableShape {
    public var edge: NotchEdge
    public var stretchDistance: CGFloat
    public var lateralOffset: CGFloat
    public var isDetached: Bool
    public var cornerRadius: CGFloat
    public var insetAmount: CGFloat

    public init(
        edge: NotchEdge = .top,
        stretchDistance: CGFloat = 0.0,
        lateralOffset: CGFloat = 0.0,
        isDetached: Bool = false,
        cornerRadius: CGFloat = 18.0,
        insetAmount: CGFloat = 0.0
    ) {
        self.edge = edge
        self.stretchDistance = max(0, stretchDistance)
        self.lateralOffset = lateralOffset
        self.isDetached = isDetached
        self.cornerRadius = cornerRadius
        self.insetAmount = insetAmount
    }

    public var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat> {
        get {
            AnimatablePair(AnimatablePair(stretchDistance, lateralOffset), cornerRadius)
        }
        set {
            stretchDistance = newValue.first.first
            lateralOffset = newValue.first.second
            cornerRadius = newValue.second
        }
    }

    public func inset(by amount: CGFloat) -> LiquidPullShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        guard insetRect.width > 0, insetRect.height > 0 else { return Path() }

        if isDetached {
            // Floating droplet capsule when detached from bezel
            return Path(roundedRect: insetRect, cornerRadius: min(insetRect.width, insetRect.height) / 2)
        }

        let depth = edge.isVertical ? insetRect.width : insetRect.height
        let length = edge.isVertical ? insetRect.height : insetRect.width

        let canonical = canonicalStretchedPath(
            in: CGRect(x: 0, y: 0, width: depth, height: length),
            stretch: stretchDistance,
            lateral: lateralOffset
        )

        return canonical
            .applying(SideNotchShape.transform(for: edge, depth: depth))
            .applying(CGAffineTransform(translationX: insetRect.minX, y: insetRect.minY))
    }

    private func canonicalStretchedPath(in rect: CGRect, stretch: CGFloat, lateral: CGFloat) -> Path {
        let corner = min(cornerRadius, min(rect.width, rect.height) / 2)

        // If no stretch, standard liquid bezel shape
        if stretch <= 0.5 {
            return SideNotchShape(edge: .right, cornerRadius: corner, curlRadius: 14)
                .path(in: rect)
        }

        // Elastic stretch ratio up to 105pt
        let maxTravel: CGFloat = 105.0
        let stretchRatio = min(1.0, max(0.0, stretch / maxTravel))

        // 1. Base anchor width against bezel
        // Contracts gracefully as stretch increases, feeling like viscous suction
        let baseLength = max(90.0, min(rect.height * 0.95, 160.0 - 55.0 * pow(stretchRatio, 0.85)))
        let baseMidY = rect.midY
        let baseTop = max(rect.minY, baseMidY - baseLength / 2)
        let baseBottom = min(rect.maxY, baseMidY + baseLength / 2)

        // 2. Pulled droplet bulb dimensions
        // Generous, rounded liquid capsule matching the detached droplet size
        let bulbWidth: CGFloat = max(56.0, 72.0 - 14.0 * stretchRatio)
        let shoulderX: CGFloat = 18.0
        let flatHalf: CGFloat = max(4.0, (bulbWidth - shoulderX * 2) / 2)

        // Lateral displacement of the pulled droplet (smooth fluid damping)
        let clampedLateral = max(-rect.height * 0.25, min(rect.height * 0.25, lateral * 0.40))
        let bulbMidY = max(rect.minY + bulbWidth / 2 + 2, min(rect.maxY - bulbWidth / 2 - 2, baseMidY + clampedLateral))
        let bulbTop = bulbMidY - flatHalf - shoulderX
        let bulbBottom = bulbMidY + flatHalf + shoulderX

        // 3. True Organic Gooey Liquid Tendon (Metaball Waist)
        let bridgeLength = max(10.0, rect.maxX - shoulderX)
        let waistProgress = 0.44 + 0.08 * stretchRatio
        let waistX = rect.maxX - bridgeLength * waistProgress
        let waistMidY = baseMidY + clampedLateral * 0.50

        // Signature gooey waist pinch: viscous honey neck thinning down to a tendon
        let waistPinch = pow(stretchRatio, 0.70)
        let waistWidth = max(12.0, 68.0 * (1.0 - 0.76 * waistPinch))
        let waistTop = waistMidY - waistWidth / 2
        let waistBottom = waistMidY + waistWidth / 2

        let dX1 = max(4.0, rect.maxX - waistX)
        let dX2 = max(4.0, waistX - shoulderX)

        let bezelX = rect.maxX + 2.0
        var path = Path()

        // Step 1: Start at bezel edge, upper anchor
        path.move(to: CGPoint(x: bezelX, y: baseTop))

        // Step 2: Bezel Flare into Upper Waist (Smooth concave flare)
        path.addCurve(
            to: CGPoint(x: waistX, y: waistTop),
            control1: CGPoint(x: rect.maxX - dX1 * 0.50, y: baseTop),
            control2: CGPoint(x: waistX + dX1 * 0.40, y: waistTop)
        )

        // Step 3: Upper Waist into Bulb Upper Shoulder (Smooth organic S-curve)
        path.addCurve(
            to: CGPoint(x: shoulderX, y: bulbTop),
            control1: CGPoint(x: waistX - dX2 * 0.40, y: waistTop),
            control2: CGPoint(x: shoulderX + dX2 * 0.45, y: bulbTop)
        )

        // Step 4: Bulb Upper Corner (Seamless G1 circular corner cap)
        path.addCurve(
            to: CGPoint(x: 0, y: bulbMidY - flatHalf),
            control1: CGPoint(x: shoulderX * 0.448, y: bulbTop),
            control2: CGPoint(x: 0, y: (bulbMidY - flatHalf) - shoulderX * 0.448)
        )

        // Step 5: Bulb Front Tip (Smooth straight pill cap edge)
        path.addLine(to: CGPoint(x: 0, y: bulbMidY + flatHalf))

        // Step 6: Bulb Lower Corner (Seamless G1 circular corner cap)
        path.addCurve(
            to: CGPoint(x: shoulderX, y: bulbBottom),
            control1: CGPoint(x: 0, y: (bulbMidY + flatHalf) + shoulderX * 0.448),
            control2: CGPoint(x: shoulderX * 0.448, y: bulbBottom)
        )

        // Step 7: Bulb Lower Shoulder into Lower Waist (Smooth organic S-curve)
        path.addCurve(
            to: CGPoint(x: waistX, y: waistBottom),
            control1: CGPoint(x: shoulderX + dX2 * 0.45, y: bulbBottom),
            control2: CGPoint(x: waistX - dX2 * 0.40, y: waistBottom)
        )

        // Step 8: Lower Waist into Bezel Base (Smooth concave flare)
        path.addCurve(
            to: CGPoint(x: bezelX, y: baseBottom),
            control1: CGPoint(x: waistX + dX1 * 0.40, y: waistBottom),
            control2: CGPoint(x: rect.maxX - dX1 * 0.50, y: baseBottom)
        )

        // Step 9: Close straight along bezel
        path.addLine(to: CGPoint(x: bezelX, y: baseTop))
        path.closeSubpath()

        return path
    }
}
