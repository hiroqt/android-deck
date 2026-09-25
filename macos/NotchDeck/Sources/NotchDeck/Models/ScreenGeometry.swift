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
        if hasPhysicalNotch {
            return CGSize(width: 180, height: max(32, topSafeAreaInset))
        } else {
            return CGSize(width: 180, height: 34)
        }
    }

    public var notchExpandedSize: CGSize {
        return CGSize(width: 480, height: 224)
    }
}
