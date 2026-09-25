import AppKit
import SwiftUI

public final class NotchHostingView<Content: View>: NSHostingView<Content> {
    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard let hitView = super.hitTest(point) else { return nil }
        let margin = NotchPanel.shadowMargin
        if bounds.width > margin * 2 && bounds.height > margin {
            let localPoint = superview != nil ? convert(point, from: superview) : point
            let activeRect = NSRect(
                x: margin,
                y: margin,
                width: bounds.width - margin * 2,
                height: bounds.height - margin
            )
            if !activeRect.contains(localPoint) {
                return nil
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
