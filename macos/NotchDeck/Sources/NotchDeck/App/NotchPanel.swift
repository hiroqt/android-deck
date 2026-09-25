import AppKit
import SwiftUI

public final class NotchHostingView<Content: View>: NSHostingView<Content> {
    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard let hitView = super.hitTest(point) else { return nil }
        let margin = NotchPanel.shadowMargin
        if bounds.width > margin * 2 && bounds.height > margin {
            let localPoint = superview != nil ? convert(point, from: superview) : point
            // Notch is anchored at the top of the window
            // In a flipped view (NSHostingView is flipped), y = 0 is the top edge!
            // The notch content is from y = 0 to y = bounds.height - margin.
            let activeRect: NSRect
            if isFlipped {
                activeRect = NSRect(
                    x: margin,
                    y: 0,
                    width: bounds.width - margin * 2,
                    height: bounds.height - margin
                )
            } else {
                activeRect = NSRect(
                    x: margin,
                    y: margin,
                    width: bounds.width - margin * 2,
                    height: bounds.height - margin
                )
            }
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
