import SwiftUI
import AppKit

public struct DeckSlotTileView: View {
    public let slot: DeckSlot
    public let isEditing: Bool
    public let onSelect: () -> Void
    public let onEdit: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var appIcon: NSImage? = nil

    public init(
        slot: DeckSlot,
        isEditing: Bool = false,
        onSelect: @escaping () -> Void,
        onEdit: @escaping () -> Void
    ) {
        self.slot = slot
        self.isEditing = isEditing
        self.onSelect = onSelect
        self.onEdit = onEdit
    }

    public var body: some View {
        Button(action: {
            if isEditing {
                onEdit()
            } else {
                onSelect()
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // Glass tile backing
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            isPressed
                                ? Color.white.opacity(0.2)
                                : (isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    isEditing
                                        ? Color.cyan.opacity(0.8)
                                        : (isHovered ? Color.white.opacity(0.3) : Color.white.opacity(0.1)),
                                    lineWidth: isEditing ? 1.5 : 1.0
                                )
                        )
                        .frame(width: 54, height: 54)

                    // Icon
                    if slot.actionType == .appLauncher, let icon = appIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                    } else if let iconName = slot.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(iconColor)
                    } else {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }

                    // Edit indicator badge
                    if isEditing {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.cyan)
                                    .background(Circle().fill(Color.black))
                                    .offset(x: 4, y: -4)
                            }
                            Spacer()
                        }
                        .frame(width: 54, height: 54)
                    }
                }

                Text(slot.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isHovered ? .white : Color(white: 0.8))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: 60)
            }
            .scaleEffect(isPressed ? 0.94 : (isHovered ? 1.05 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onHover { isHovered = $0 }
        .onAppear { loadAppIconIfNeeded() }
        .onChange(of: slot.target) { loadAppIconIfNeeded() }
    }

    private var iconColor: Color {
        if slot.actionType == .systemToggle && slot.target == "micMute" {
            return SystemControlService.shared.isMicMuted() ? .red : .green
        }
        return .white
    }

    private func loadAppIconIfNeeded() {
        if slot.actionType == .appLauncher {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: slot.target) {
                self.appIcon = NSWorkspace.shared.icon(forFile: url.path)
            }
        }
    }
}
