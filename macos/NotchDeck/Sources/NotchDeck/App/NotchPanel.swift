import AppKit
import SwiftUI

public final class NotchHostingView<Content: View>: NSHostingView<Content> {
    public var currentEdge: NotchEdge = .top
    public var isDetached: Bool = false

    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard let hitView = super.hitTest(point) else { return nil }
        let margin = NotchPanel.shadowMargin
        let localPoint = superview != nil ? convert(point, from: superview) : point

        if isDetached {
            let activeRect = NSRect(
                x: margin,
                y: margin,
                width: max(0, bounds.width - margin * 2),
                height: max(0, bounds.height - margin * 2)
            )
            return activeRect.contains(localPoint) ? hitView : nil
        }

        let activeRect: NSRect
        switch currentEdge {
        case .top:
            if bounds.width > margin * 2 && bounds.height > margin {
                activeRect = NSRect(
                    x: margin,
                    y: isFlipped ? 0 : margin,
                    width: bounds.width - margin * 2,
                    height: bounds.height - margin
                )
                if !activeRect.contains(localPoint) {
                    return nil
                }
            }
        case .right:
            if bounds.width > margin && bounds.height > margin * 2 {
                activeRect = NSRect(
                    x: margin,
                    y: margin,
                    width: bounds.width - margin,
                    height: bounds.height - margin * 2
                )
                if !activeRect.contains(localPoint) {
                    return nil
                }
            }
        case .left:
            if bounds.width > margin && bounds.height > margin * 2 {
                activeRect = NSRect(
                    x: 0,
                    y: margin,
                    width: bounds.width - margin,
                    height: bounds.height - margin * 2
                )
                if !activeRect.contains(localPoint) {
                    return nil
                }
            }
        }
        return hitView
    }
}

public final class NotchPanel: NSPanel {
    public static let shadowMargin: CGFloat = 24.0

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isFloatingPanel = true
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.isMovable = false
    }

    public override var canBecomeKey: Bool {
        return true
    }
}

public final class NotchBubblePanel: NSPanel {
    public init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 36),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isFloatingPanel = true
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.isMovable = false
        self.alphaValue = 0.0
    }
}
