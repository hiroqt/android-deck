import SwiftUI

public struct CollapsedNotchView: View {
    @ObservedObject var phoneDeckService = PhoneDeckService.shared
    public let hasPhysicalNotch: Bool
    public let onExpand: () -> Void

    @State private var isHovered = false

    public init(
        phoneDeckService: PhoneDeckService = .shared,
        hasPhysicalNotch: Bool = false,
        onExpand: @escaping () -> Void
    ) {
        self.phoneDeckService = phoneDeckService
        self.hasPhysicalNotch = hasPhysicalNotch
        self.onExpand = onExpand
    }

    public var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 7) {
                Circle()
                    .fill(phoneDeckService.isDeviceConnected ? Color.green : Color.white.opacity(0.35))
                    .frame(width: 6, height: 6)
                    .shadow(color: phoneDeckService.isDeviceConnected ? Color.green.opacity(0.8) : Color.clear, radius: 2)

                Text("Deck")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(isHovered ? 0.95 : 0.8))

                Circle()
                    .fill(Color.white.opacity(isHovered ? 0.5 : 0.35))
                    .frame(width: 4, height: 4)
            }
            .frame(width: 180, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
