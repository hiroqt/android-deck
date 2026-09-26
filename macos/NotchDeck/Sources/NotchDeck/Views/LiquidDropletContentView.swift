import SwiftUI

/// Compact liquid droplet content view displayed during pulling and dragging.
///
/// Shows ONLY the liquid status and phone charge indicator inside the elastic
/// liquid bulb or detached floating droplet — hiding the full deck notch to
/// maintain a fluid, lightweight appearance during movement.
public struct LiquidDropletContentView: View {
    public let edge: NotchEdge
    @ObservedObject public var phoneDeckService: PhoneDeckService
    public let isDetached: Bool
    public var dragTargetEdge: NotchEdge? = nil

    public init(
        edge: NotchEdge = .top,
        phoneDeckService: PhoneDeckService = .shared,
        isDetached: Bool = false,
        dragTargetEdge: NotchEdge? = nil
    ) {
        self.edge = edge
        self.phoneDeckService = phoneDeckService
        self.isDetached = isDetached
        self.dragTargetEdge = dragTargetEdge
    }

    private var statusColor: Color {
        if phoneDeckService.isDeviceConnected {
            return Color(red: 0.20, green: 0.84, blue: 0.29) // iOS vibrant green
        } else {
            return Color(red: 1.00, green: 0.62, blue: 0.04) // Amber / orange
        }
    }

    public var body: some View {
        if !isDetached {
            // While stretching/pulling from notch: Pure organic liquid droplet!
            // NO TEXT! Just the subtle, clean glowing status dot centered in the droplet bulb.
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .shadow(color: statusColor.opacity(0.85), radius: 3)
        } else {
            // Detached floating droplet mode
            if !edge.isVertical {
                horizontalDropletContent
            } else {
                verticalDropletContent
            }
        }
    }

    private var horizontalDropletContent: some View {
        HStack(spacing: 5) {
            // Glowing status dot or docking indicator
            if let target = dragTargetEdge {
                Image(systemName: target == .top ? "arrow.up.to.line" : (target == .right ? "arrow.right.to.line" : "arrow.left.to.line"))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.cyan)
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                    .shadow(color: statusColor.opacity(0.8), radius: 3)
            }

            // Phone charge / status indicator (only when battery level is available)
            if let level = phoneDeckService.batteryLevel {
                HStack(spacing: 2) {
                    if phoneDeckService.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(statusColor)
                    }
                    Text("\(level)%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
    }

    private var verticalDropletContent: some View {
        VStack(spacing: 4) {
            // Glowing status dot or docking indicator
            if let target = dragTargetEdge {
                Image(systemName: target == .top ? "arrow.up.to.line" : (target == .right ? "arrow.right.to.line" : "arrow.left.to.line"))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.cyan)
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                    .shadow(color: statusColor.opacity(0.8), radius: 3)
            }

            // Phone charge / status indicator (only when battery level is available)
            if let level = phoneDeckService.batteryLevel {
                VStack(spacing: 1) {
                    if phoneDeckService.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(statusColor)
                    }
                    Text("\(level)%")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}
