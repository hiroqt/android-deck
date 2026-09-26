import SwiftUI

/// Minimal extended chat bubble displayed adjacent to the side notch on hover.
///
/// Communicates current device sync/battery status in an ultra-clean, minimal callout
/// with liquid obsidian material and a subtle tail pointing towards the screen edge.
public struct SideNotchBubbleView: View {
    @ObservedObject var phoneDeckService: PhoneDeckService
    public let edge: NotchEdge

    public init(phoneDeckService: PhoneDeckService = .shared, edge: NotchEdge = .right) {
        self.phoneDeckService = phoneDeckService
        self.edge = edge
    }

    private var statusColor: Color {
        if phoneDeckService.isDeviceConnected {
            return Color(red: 0.20, green: 0.84, blue: 0.29) // iOS vibrant green
        } else {
            return Color(red: 1.00, green: 0.62, blue: 0.04) // Amber / orange
        }
    }

    private var bubbleShape: ChatBubbleShape {
        ChatBubbleShape(edge: edge, cornerRadius: 10, tailWidth: 5, tailHeight: 8)
    }

    public var body: some View {
        HStack(spacing: 6) {
            // Glowing status indicator dot
            Circle()
                .fill(statusColor)
                .frame(width: 5, height: 5)
                .shadow(color: statusColor.opacity(0.85), radius: 2)

            if phoneDeckService.isDeviceConnected {
                let name = phoneDeckService.connectedDeviceName ?? "Phone"
                Text(name)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                if let level = phoneDeckService.batteryLevel {
                    Text("•")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.35))

                    HStack(spacing: 2) {
                        if phoneDeckService.isCharging {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(statusColor)
                        }
                        Text("\(level)%")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            } else {
                Text("Waiting for Phone...")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.92))
            }
        }
        .padding(.leading, edge == .left ? 11 : 8)
        .padding(.trailing, edge == .right ? 11 : 8)
        .padding(.vertical, 5)
        .background(
            bubbleShape
                .fill(.ultraThinMaterial)
                .overlay(
                    bubbleShape
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 6, x: edge == .right ? -2 : 2, y: 2)
        )
        .fixedSize()
    }
}
