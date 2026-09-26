import SwiftUI

/// An organic chat bubble shape with an integrated tail pointing towards the screen edge.
public struct ChatBubbleShape: Shape, InsettableShape {
    public var edge: NotchEdge
    public var cornerRadius: CGFloat
    public var tailWidth: CGFloat
    public var tailHeight: CGFloat
    public var insetAmount: CGFloat

    public init(
        edge: NotchEdge = .right,
        cornerRadius: CGFloat = 10.0,
        tailWidth: CGFloat = 5.0,
        tailHeight: CGFloat = 8.0,
        insetAmount: CGFloat = 0.0
    ) {
        self.edge = edge
        self.cornerRadius = cornerRadius
        self.tailWidth = tailWidth
        self.tailHeight = tailHeight
        self.insetAmount = insetAmount
    }

    public func inset(by amount: CGFloat) -> ChatBubbleShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        guard insetRect.width > 0, insetRect.height > 0 else { return Path() }

        let r = min(cornerRadius, insetRect.height / 2)
        var path = Path()

        if edge == .right {
            // Bubble sits on the left, tail points right towards the docked notch
            let bodyMaxX = insetRect.maxX - tailWidth
            let tailTipX = insetRect.maxX
            let midY = insetRect.midY
            let halfTail = tailHeight / 2

            // Start top-left
            path.move(to: CGPoint(x: insetRect.minX + r, y: insetRect.minY))
            // Top edge to bodyMaxX
            path.addLine(to: CGPoint(x: bodyMaxX - r, y: insetRect.minY))
            // Top-right corner
            path.addQuadCurve(
                to: CGPoint(x: bodyMaxX, y: insetRect.minY + r),
                control: CGPoint(x: bodyMaxX, y: insetRect.minY)
            )
            // Down to top of tail
            path.addLine(to: CGPoint(x: bodyMaxX, y: midY - halfTail))
            // Out to tail tip
            path.addLine(to: CGPoint(x: tailTipX, y: midY))
            // Back to bottom of tail
            path.addLine(to: CGPoint(x: bodyMaxX, y: midY + halfTail))
            // Down to bottom-right corner
            path.addLine(to: CGPoint(x: bodyMaxX, y: insetRect.maxY - r))
            // Bottom-right corner
            path.addQuadCurve(
                to: CGPoint(x: bodyMaxX - r, y: insetRect.maxY),
                control: CGPoint(x: bodyMaxX, y: insetRect.maxY)
            )
            // Bottom edge
            path.addLine(to: CGPoint(x: insetRect.minX + r, y: insetRect.maxY))
            // Bottom-left corner
            path.addQuadCurve(
                to: CGPoint(x: insetRect.minX, y: insetRect.maxY - r),
                control: CGPoint(x: insetRect.minX, y: insetRect.maxY)
            )
            // Left edge
            path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY + r))
            // Top-left corner
            path.addQuadCurve(
                to: CGPoint(x: insetRect.minX + r, y: insetRect.minY),
                control: CGPoint(x: insetRect.minX, y: insetRect.minY)
            )
            path.closeSubpath()

        } else if edge == .left {
            // Bubble sits on the right, tail points left towards the docked notch
            let bodyMinX = insetRect.minX + tailWidth
            let tailTipX = insetRect.minX
            let midY = insetRect.midY
            let halfTail = tailHeight / 2

            // Start top-left of body
            path.move(to: CGPoint(x: bodyMinX + r, y: insetRect.minY))
            // Top edge
            path.addLine(to: CGPoint(x: insetRect.maxX - r, y: insetRect.minY))
            // Top-right corner
            path.addQuadCurve(
                to: CGPoint(x: insetRect.maxX, y: insetRect.minY + r),
                control: CGPoint(x: insetRect.maxX, y: insetRect.minY)
            )
            // Right edge
            path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - r))
            // Bottom-right corner
            path.addQuadCurve(
                to: CGPoint(x: insetRect.maxX - r, y: insetRect.maxY),
                control: CGPoint(x: insetRect.maxX, y: insetRect.maxY)
            )
            // Bottom edge to bodyMinX
            path.addLine(to: CGPoint(x: bodyMinX + r, y: insetRect.maxY))
            // Bottom-left corner
            path.addQuadCurve(
                to: CGPoint(x: bodyMinX, y: insetRect.maxY - r),
                control: CGPoint(x: bodyMinX, y: insetRect.maxY)
            )
            // Up to bottom of tail
            path.addLine(to: CGPoint(x: bodyMinX, y: midY + halfTail))
            // Out to tail tip
            path.addLine(to: CGPoint(x: tailTipX, y: midY))
            // Back to top of tail
            path.addLine(to: CGPoint(x: bodyMinX, y: midY - halfTail))
            // Up to top-left corner
            path.addLine(to: CGPoint(x: bodyMinX, y: insetRect.minY + r))
            // Top-left corner
            path.addQuadCurve(
                to: CGPoint(x: bodyMinX + r, y: insetRect.minY),
                control: CGPoint(x: bodyMinX, y: insetRect.minY)
            )
            path.closeSubpath()

        } else {
            // Horizontal top notch fallback: clean rounded capsule
            return Path(roundedRect: insetRect, cornerRadius: r)
        }

        return path
    }
}
