import SwiftUI

/// An organic liquid notch shape welded to the screen bezel.
///
/// Features smooth continuous inverse fillets (flares) that curve outward from the bezel
/// into the notch body, followed by continuous curvature corners facing into the screen.
public struct SideNotchShape: Shape, InsettableShape {
    public var edge: NotchEdge
    public var cornerRadius: CGFloat
    public var curlRadius: CGFloat
    public var filletRamp: CGFloat
    public var insetAmount: CGFloat

    public init(
        edge: NotchEdge = .top,
        cornerRadius: CGFloat = 18.0,
        curlRadius: CGFloat = 16.0,
        filletRamp: CGFloat = 0.5,
        insetAmount: CGFloat = 0.0
    ) {
        self.edge = edge
        self.cornerRadius = cornerRadius
        self.curlRadius = curlRadius
        self.filletRamp = filletRamp
        self.insetAmount = insetAmount
    }

    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(cornerRadius, curlRadius) }
        set {
            cornerRadius = newValue.first
            curlRadius = newValue.second
        }
    }

    public func inset(by amount: CGFloat) -> SideNotchShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        guard insetRect.width > 0, insetRect.height > 0 else { return Path() }

        let depth = edge.isVertical ? insetRect.width : insetRect.height
        let length = edge.isVertical ? insetRect.height : insetRect.width

        let canonical = canonicalPath(
            in: CGRect(x: 0, y: 0, width: depth, height: length),
            curl: curlRadius,
            corner: cornerRadius
        )

        return canonical
            .applying(Self.transform(for: edge, depth: depth))
            .applying(CGAffineTransform(translationX: insetRect.minX, y: insetRect.minY))
    }

    /// Canonical coordinate mapping:
    /// In canonical space, the bezel is at `x = depth` (`maxX`).
    /// `x` runs across the shape from inner edge (0) to bezel (depth).
    /// `y` runs along the shape from 0 to `length`.
    public static func transform(for edge: NotchEdge, depth: CGFloat) -> CGAffineTransform {
        switch edge {
        case .right:
            return .identity
        case .left:
            // Mirrored across X: bezel at x = 0
            return CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: depth, ty: 0)
        case .top:
            // Quarter turn: bezel at y = 0
            return CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: depth)
        }
    }

    private static let circleReach: CGFloat = 0.5522847498

    private func fluidTurn(
        _ path: inout Path,
        to: CGPoint,
        leaving: CGVector,
        arriving: CGVector,
        ramp: CGFloat
    ) {
        guard let from = path.currentPoint else { return }
        let alongReach = (to.x - from.x) * leaving.dx + (to.y - from.y) * leaving.dy
        let acrossReach = (to.x - from.x) * arriving.dx + (to.y - from.y) * arriving.dy
        guard alongReach != 0, acrossReach != 0 else {
            path.addLine(to: to)
            return
        }
        let p = min(max(ramp, 0), 0.5)
        let bend = (CGFloat.pi / 2) / max(0.001, 1 - p)
        let steps = 48
        var heading: CGFloat = 0, u: CGFloat = 0, v: CGFloat = 0
        var walk: [(CGFloat, CGFloat)] = [(0, 0)]
        for i in 0..<steps {
            let s = (CGFloat(i) + 0.5) / CGFloat(steps)
            let share = p <= 0 ? 1 : (s < p ? s / p : (s > 1 - p ? (1 - s) / p : 1))
            heading += bend * share / CGFloat(steps)
            u += cos(heading) / CGFloat(steps)
            v += sin(heading) / CGFloat(steps)
            walk.append((u, v))
        }
        let (endU, endV) = walk[walk.count - 1]
        guard endU != 0, endV != 0 else {
            path.addLine(to: to)
            return
        }
        let alongScale = alongReach / endU, acrossScale = acrossReach / endV
        for (wu, wv) in walk.dropFirst() {
            path.addLine(to: CGPoint(
                x: from.x + leaving.dx * wu * alongScale + arriving.dx * wv * acrossScale,
                y: from.y + leaving.dy * wu * alongScale + arriving.dy * wv * acrossScale
            ))
        }
    }

    private func turn(
        _ path: inout Path,
        to: CGPoint,
        leaving: CGVector,
        arriving: CGVector,
        radius: CGFloat
    ) {
        guard radius > 0, let from = path.currentPoint else {
            path.addLine(to: to)
            return
        }
        let delta = CGVector(dx: to.x - from.x, dy: to.y - from.y)
        let out = abs(delta.dx * leaving.dx + delta.dy * leaving.dy)
        let into = abs(delta.dx * arriving.dx + delta.dy * arriving.dy)
        guard out > 0, into > 0 else {
            path.addLine(to: to)
            return
        }
        path.addCurve(
            to: to,
            control1: CGPoint(x: from.x + leaving.dx * out * Self.circleReach,
                              y: from.y + leaving.dy * out * Self.circleReach),
            control2: CGPoint(x: to.x - arriving.dx * into * Self.circleReach,
                              y: to.y - arriving.dy * into * Self.circleReach)
        )
    }

    private func canonicalPath(in rect: CGRect, curl: CGFloat, corner: CGFloat) -> Path {
        let wantedCorner = max(0, min(corner, rect.width / 2))
        let curlDepth = max(0, min(curl, rect.width - wantedCorner))
        let actualCurl = max(0, min(curl, rect.height / 2))
        let actualCorner = max(0, min(wantedCorner, (rect.height - 2 * actualCurl) / 2))
        let bodyTop = rect.minY + actualCurl
        let bodyBottom = rect.maxY - actualCurl

        var path = Path()
        // Start on bezel edge at top corner
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Flare inward and down onto body's top edge
        if actualCurl > 0 {
            fluidTurn(
                &path,
                to: CGPoint(x: rect.maxX - curlDepth, y: bodyTop),
                leaving: CGVector(dx: 0, dy: 1),
                arriving: CGVector(dx: -1, dy: 0),
                ramp: filletRamp
            )
        }

        // Top edge running inward towards display
        path.addLine(to: CGPoint(x: rect.minX + actualCorner, y: bodyTop))

        // Turn around outer corner facing display
        turn(
            &path,
            to: CGPoint(x: rect.minX, y: bodyTop + actualCorner),
            leaving: CGVector(dx: -1, dy: 0),
            arriving: CGVector(dx: 0, dy: 1),
            radius: actualCorner
        )

        // Straight inner edge
        path.addLine(to: CGPoint(x: rect.minX, y: bodyBottom - actualCorner))

        // Turn around bottom outer corner
        turn(
            &path,
            to: CGPoint(x: rect.minX + actualCorner, y: bodyBottom),
            leaving: CGVector(dx: 0, dy: 1),
            arriving: CGVector(dx: 1, dy: 0),
            radius: actualCorner
        )

        // Bottom edge running outward toward bezel
        path.addLine(to: CGPoint(x: rect.maxX - curlDepth, y: bodyBottom))

        // Flare back out to bezel edge
        if actualCurl > 0 {
            fluidTurn(
                &path,
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                leaving: CGVector(dx: 1, dy: 0),
                arriving: CGVector(dx: 0, dy: 1),
                ramp: filletRamp
            )
        }

        // Close along bezel
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
