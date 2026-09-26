import Foundation

/// Which screen edge the notch is docked to.
public enum NotchEdge: String, Codable, CaseIterable, Identifiable, Sendable {
    case top
    case left
    case right

    public var id: String { rawValue }

    /// True when the notch runs vertically along the screen edge (left or right).
    public var isVertical: Bool {
        return self == .left || self == .right
    }

    public var title: String {
        switch self {
        case .top: return "Top"
        case .left: return "Left"
        case .right: return "Right"
        }
    }

    public var systemImage: String {
        switch self {
        case .top: return "menubar.arrow.up.rectangle"
        case .left: return "sidebar.left"
        case .right: return "sidebar.right"
        }
    }

    /// Unit vector pointing toward the screen bezel/border.
    public var outwardVector: CGPoint {
        switch self {
        case .top: return CGPoint(x: 0, y: -1)
        case .left: return CGPoint(x: -1, y: 0)
        case .right: return CGPoint(x: 1, y: 0)
        }
    }
}
