import SwiftUI
import AppKit

public struct DeckSlotCardView: View {
    public let slot: PhoneDeckSlot
    public var cardWidth: CGFloat? = nil
    public var cardHeight: CGFloat? = nil
    public let onEdit: () -> Void
    public let onRemove: () -> Void

    @State private var isHovered = false
    @State private var appIcon: NSImage? = nil

    public init(
        slot: PhoneDeckSlot,
        cardWidth: CGFloat? = nil,
        cardHeight: CGFloat? = nil,
        onEdit: @escaping () -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.slot = slot
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.onEdit = onEdit
        self.onRemove = onRemove
    }

    private var effectiveWidth: CGFloat {
        cardWidth ?? 132
    }

    private var effectiveHeight: CGFloat {
        cardHeight ?? 74
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Card Button
            Button(action: onEdit) {
                ZStack {
                    if slot.isEmpty {
                        // Empty State Card (+)
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(isHovered ? 0.08 : 0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 1.2, dash: [4, 4])
                                    )
                                    .foregroundColor(isHovered ? Color.cyan.opacity(0.7) : Color.white.opacity(0.16))
                            )

                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(isHovered ? .cyan : Color.white.opacity(0.5))

                            Text("Slot \(slot.index + 1)")
                                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                                .foregroundColor(isHovered ? Color.white.opacity(0.9) : Color.white.opacity(0.5))
                        }
                    } else {
                        // Configured App Card
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(isHovered ? 0.10 : 0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
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
                                    .frame(width: 32, height: 32)
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue.opacity(0.65), Color.purple.opacity(0.65)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 32, height: 32)

                                    Text(slot.label.prefix(1).uppercased().isEmpty ? "?" : slot.label.prefix(1).uppercased())
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }

                            Text(slot.label.isEmpty ? "App \(slot.index + 1)" : slot.label)
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                .foregroundColor(isHovered ? .white : Color(white: 0.88))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: effectiveWidth - 20)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                    }
                }
                .frame(width: effectiveWidth, height: effectiveHeight)
                .shadow(color: Color.black.opacity(isHovered ? 0.3 : 0.15), radius: 4, y: 1.5)
            }
            .buttonStyle(.plain)

            // Small minus badge (-) kept strictly inside card corner, shown on hover
            if !slot.isEmpty {
                Button(action: onRemove) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.95, green: 0.25, blue: 0.25))
                            .frame(width: 16, height: 16)
                            .shadow(color: Color.black.opacity(0.35), radius: 2, y: 1)

                        Image(systemName: "minus")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .help("Remove app from slot")
                .padding([.top, .trailing], 5)
                .opacity(isHovered ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
            }
        }
        .frame(width: effectiveWidth, height: effectiveHeight)
        .onHover { isHovered = $0 }
        .onAppear { loadAppIcon() }
        .onChange(of: slot.bundleId) { loadAppIcon() }
        .onChange(of: slot.label) { loadAppIcon() }
    }

    private func loadAppIcon() {
        guard !slot.isEmpty else {
            self.appIcon = nil
            return
        }
        if let cached = AppIconManager.shared.icon(for: slot.bundleId, name: slot.label) {
            self.appIcon = cached
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let icon = AppIconManager.shared.icon(for: self.slot.bundleId, name: self.slot.label)
            DispatchQueue.main.async {
                self.appIcon = icon
            }
        }
    }
}
