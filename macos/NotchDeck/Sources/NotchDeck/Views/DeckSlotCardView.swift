import SwiftUI
import AppKit

public struct DeckSlotCardView: View {
    public let slot: PhoneDeckSlot
    public let onEdit: () -> Void
    public let onRemove: () -> Void

    @State private var isHovered = false
    @State private var appIcon: NSImage? = nil

    public init(
        slot: PhoneDeckSlot,
        onEdit: @escaping () -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.slot = slot
        self.onEdit = onEdit
        self.onRemove = onRemove
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Card Button
            Button(action: onEdit) {
                ZStack {
                    if slot.isEmpty {
                        // Empty State Card (+)
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(isHovered ? 0.08 : 0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 1.2, dash: [4, 4])
                                    )
                                    .foregroundColor(isHovered ? Color.cyan.opacity(0.7) : Color.white.opacity(0.16))
                            )

                        VStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(isHovered ? .cyan : Color.white.opacity(0.5))

                            Text("Slot \(slot.index + 1)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(isHovered ? Color.white.opacity(0.9) : Color.white.opacity(0.5))
                        }
                    } else {
                        // Configured App Card
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(isHovered ? 0.10 : 0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            stops: [
                                                .init(color: Color.white.opacity(isHovered ? 0.35 : 0.20), location: 0.0),
                                                .init(color: Color.white.opacity(0.06), location: 1.0)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1.0
                                    )
                            )

                        VStack(spacing: 4) {
                            if let icon = appIcon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 36, height: 36)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            } else {
                                Image(systemName: "app.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                            }

                            Text(slot.label.isEmpty ? "App \(slot.index + 1)" : slot.label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(isHovered ? .white : Color(white: 0.88))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: 110)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 8)
                    }
                }
                .frame(width: 132, height: 74)
                .shadow(color: Color.black.opacity(isHovered ? 0.3 : 0.15), radius: 6, y: 2)
            }
            .buttonStyle(.plain)

            // Small minus badge (-) in top right
            if !slot.isEmpty {
                Button(action: onRemove) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.95, green: 0.25, blue: 0.25))
                            .frame(width: 18, height: 18)
                            .shadow(color: Color.black.opacity(0.4), radius: 2, y: 1)

                        Image(systemName: "minus")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .help("Remove app from slot")
                .offset(x: -6, y: 6)
            }
        }
        .scaleEffect(isHovered ? 1.025 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.72), value: isHovered)
        .onHover { isHovered = $0 }
        .onAppear { loadAppIcon() }
        .onChange(of: slot.bundleId) { loadAppIcon() }
    }

    private func loadAppIcon() {
        guard !slot.isEmpty else {
            self.appIcon = nil
            return
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: slot.bundleId) {
            self.appIcon = NSWorkspace.shared.icon(forFile: url.path)
        } else {
            self.appIcon = nil
        }
    }
}
