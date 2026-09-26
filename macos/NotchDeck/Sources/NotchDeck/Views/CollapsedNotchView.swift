import SwiftUI

public struct CollapsedNotchView: View {
    @ObservedObject var phoneDeckService = PhoneDeckService.shared
    public let edge: NotchEdge
    public let hasPhysicalNotch: Bool
    public var notchWidth: CGFloat
    public var notchHeight: CGFloat
    public var physicalNotchWidth: CGFloat
    public let onExpand: () -> Void

    @State private var isHovered = false

    public init(
        phoneDeckService: PhoneDeckService = .shared,
        edge: NotchEdge = .top,
        hasPhysicalNotch: Bool = false,
        notchWidth: CGFloat = 180,
        notchHeight: CGFloat = 32,
        physicalNotchWidth: CGFloat = 180,
        onExpand: @escaping () -> Void
    ) {
        self.phoneDeckService = phoneDeckService
        self.edge = edge
        self.hasPhysicalNotch = hasPhysicalNotch
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
        self.physicalNotchWidth = physicalNotchWidth
        self.onExpand = onExpand
    }

    public var body: some View {
        if edge.isVertical {
            verticalSidebarView
        } else {
            horizontalTopView
        }
    }

    // MARK: - Horizontal Top View
    private var horizontalTopView: some View {
        Button(action: onExpand) {
            if hasPhysicalNotch {
                physicalNotchTopView
            } else {
                simulatedNotchTopView
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    // MARK: - Physical Notch Top View (M-Series Mac with hardware camera cutout)
    private var physicalNotchTopView: some View {
        ZStack(alignment: .top) {
            // Left & Right Wings flanking the physical camera cutout
            HStack(alignment: .center, spacing: 0) {
                // Left Wing: Status Dot & Brand Label (Completely to the left of the camera notch)
                HStack(spacing: 5) {
                    Circle()
                        .fill(phoneDeckService.isDeviceConnected ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                        .shadow(color: (phoneDeckService.isDeviceConnected ? Color.green : Color.orange).opacity(0.8), radius: 2)

                    Text("Deck")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(isHovered ? 0.95 : 0.8))
                }
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 32)

                // Hardware Camera Notch Center Exclusion Zone
                // Guarantees zero text or icons can ever be covered by the physical camera cutout!
                Spacer()
                    .frame(width: max(physicalNotchWidth, 180) + 20)

                // Right Wing: Phone / Battery Indicator (Completely to the right of the camera notch)
                HStack(spacing: 4) {
                    if phoneDeckService.isDeviceConnected {
                        if let battery = phoneDeckService.batteryLevel {
                            HStack(spacing: 3) {
                                Image(systemName: batterySymbol(level: battery, isCharging: phoneDeckService.isCharging))
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(batteryIconColor(level: battery, isCharging: phoneDeckService.isCharging))

                                Text("\(battery)%")
                                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                    .foregroundColor(batteryTextColor(level: battery))

                                if phoneDeckService.isCharging {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.green)
                                }
                            }
                        } else {
                            HStack(spacing: 3) {
                                Image(systemName: "iphone")
                                    .font(.system(size: 9.5, weight: .medium))
                                    .foregroundColor(.green)

                                Text("Ready")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.85))
                            }
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "iphone.slash")
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(Color.white.opacity(isHovered ? 0.65 : 0.45))

                            Text("Offline")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(isHovered ? 0.6 : 0.4))
                        }
                    }
                }
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(height: 32)
            }

            // Bottom Chin (visible tactile lip extending below the physical notch)
            VStack {
                Spacer()
                Capsule()
                    .fill(Color.white.opacity(isHovered ? 0.4 : 0.2))
                    .frame(width: 36, height: 3)
                    .padding(.bottom, 4)
            }
        }
        .frame(width: notchWidth > 0 ? notchWidth : (hasPhysicalNotch ? 360 : 184), height: notchHeight > 0 ? notchHeight : (hasPhysicalNotch ? 44 : 34))
        .background(Color.black.opacity(0.001))
        .contentShape(Rectangle())
    }

    // MARK: - Simulated Notch Top View (External displays and non-notch Macs)
    private var simulatedNotchTopView: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(phoneDeckService.isDeviceConnected ? Color.green : Color.white.opacity(0.35))
                .frame(width: 6, height: 6)
                .shadow(color: phoneDeckService.isDeviceConnected ? Color.green.opacity(0.8) : Color.clear, radius: 2)

            Text("Deck")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color.white.opacity(isHovered ? 0.95 : 0.8))

            if phoneDeckService.isDeviceConnected {
                if let battery = phoneDeckService.batteryLevel {
                    HStack(spacing: 3) {
                        Image(systemName: batterySymbol(level: battery, isCharging: phoneDeckService.isCharging))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(batteryIconColor(level: battery, isCharging: phoneDeckService.isCharging))

                        Text("\(battery)%")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(batteryTextColor(level: battery))

                        if phoneDeckService.isCharging {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                            )
                    )
                } else {
                    HStack(spacing: 3) {
                        Image(systemName: "iphone")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.green)

                        Text("Ready")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.9))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                            )
                    )
                }
            } else {
                Circle()
                    .fill(Color.white.opacity(isHovered ? 0.5 : 0.35))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(width: notchWidth > 0 ? notchWidth : 184, height: notchHeight > 0 ? notchHeight : 34)
        .background(Color.black.opacity(0.001))
        .contentShape(Rectangle())
    }

    // MARK: - Vertical Sidebar View (Phone Charge & Status Only, No Overlap)
    private var verticalSidebarView: some View {
        Button(action: onExpand) {
            VStack(spacing: 8) {
                // Connection Status Indicator Dot (Clean & Unobtrusive)
                Circle()
                    .fill(phoneDeckService.isDeviceConnected ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
                    .shadow(color: phoneDeckService.isDeviceConnected ? Color.green.opacity(0.85) : Color.orange.opacity(0.5), radius: 3)
                    .padding(.top, 14)

                // Single Phone Charge Ring Gauge
                VStack(spacing: 4) {
                    ZStack {
                        // Track
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 2.8)
                            .frame(width: 28, height: 28)

                        // Battery Level Progress Arc (only when connected and level known)
                        if let level = currentBatteryLevel {
                            Circle()
                                .trim(from: 0, to: CGFloat(level) / 100.0)
                                .stroke(
                                    batteryArcColor,
                                    style: StrokeStyle(lineWidth: 2.8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 28, height: 28)
                                .shadow(color: batteryArcColor.opacity(0.4), radius: 2)
                        }

                        // Phone / Charging Icon
                        Image(systemName: batteryCenterIcon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    if let level = currentBatteryLevel {
                        Text("\(level)%")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.92))
                    } else {
                        Text("Sync")
                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.55))
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(width: 48, height: 116)
            .background(Color.black.opacity(0.001))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            self.isHovered = isHovered
            NotchWindowController.shared.setSideNotchHovered(isHovered)
        }
    }

    private var currentBatteryLevel: Int? {
        if phoneDeckService.isDeviceConnected {
            return phoneDeckService.batteryLevel
        }
        return nil
    }

    private var batteryCenterIcon: String {
        if phoneDeckService.isDeviceConnected {
            if phoneDeckService.isCharging {
                return "bolt.fill"
            }
            return "iphone"
        }
        return "iphone.slash"
    }

    private var batteryArcColor: Color {
        if phoneDeckService.isDeviceConnected {
            if phoneDeckService.isCharging {
                return .green
            } else if let level = currentBatteryLevel {
                if level <= 20 {
                    return .red
                } else if level <= 35 {
                    return .orange
                } else {
                    return .green
                }
            }
        }
        return Color.white.opacity(0.2)
    }

    private func batterySymbol(level: Int, isCharging: Bool) -> String {
        switch level {
        case 75...100: return "battery.100"
        case 50..<75: return "battery.75"
        case 25..<50: return "battery.50"
        default: return "battery.25"
        }
    }

    private func batteryIconColor(level: Int, isCharging: Bool) -> Color {
        if isCharging {
            return .green
        } else if level <= 20 {
            return .red
        } else if level <= 35 {
            return .orange
        } else {
            return Color.white.opacity(0.85)
        }
    }

    private func batteryTextColor(level: Int) -> Color {
        if level <= 20 {
            return .red
        } else {
            return Color.white.opacity(0.9)
        }
    }
}
