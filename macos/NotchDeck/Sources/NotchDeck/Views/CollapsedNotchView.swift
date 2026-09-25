import SwiftUI

public struct CollapsedNotchView: View {
    public let hasPhysicalNotch: Bool
    public let onExpand: () -> Void

    @State private var isHovered = false

    public init(
        hasPhysicalNotch: Bool = false,
        onExpand: @escaping () -> Void
    ) {
        self.hasPhysicalNotch = hasPhysicalNotch
        self.onExpand = onExpand
    }

    public var body: some View {
        Button(action: onExpand) {
            ZStack {
                LiquidGlassBackground(
                    cornerRadius: hasPhysicalNotch ? 12 : 16,
                    specularIntensity: isHovered ? 0.6 : 0.35,
                    isExpanded: false
                )

                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)

                    Text("Deck")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))

                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 180, height: 32)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
