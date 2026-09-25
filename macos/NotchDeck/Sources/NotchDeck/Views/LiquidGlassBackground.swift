import SwiftUI
import AppKit

public struct VisualEffectView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public init(material: NSVisualEffectView.Material = .hudWindow, blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

public struct LiquidGlassBackground: View {
    public let cornerRadius: CGFloat
    public let specularIntensity: Double
    public let isExpanded: Bool

    public init(cornerRadius: CGFloat = 24.0, specularIntensity: Double = 0.45, isExpanded: Bool = true) {
        self.cornerRadius = cornerRadius
        self.specularIntensity = specularIntensity
        self.isExpanded = isExpanded
    }

    public init(settings: GlassAppearanceSettings, isExpanded: Bool = true) {
        self.cornerRadius = CGFloat(settings.cornerRadius)
        self.specularIntensity = settings.specularIntensity
        self.isExpanded = isExpanded
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                // Dark acrylic tint gradient for deep obsidian-glass look
                LinearGradient(
                    colors: [
                        Color(white: 0.12, opacity: 0.90),
                        Color(white: 0.04, opacity: 0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                // Ambient inner sheen
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.06), location: 0.0),
                                .init(color: Color.clear, location: 0.35)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                // Directional Specular Reflection Rim
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(specularIntensity), location: 0.0),
                                .init(color: Color.white.opacity(specularIntensity * 0.4), location: 0.25),
                                .init(color: Color.white.opacity(0.08), location: 0.7),
                                .init(color: Color.white.opacity(0.02), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.0
                    )
            )
            .background(
                // Shape-matched drop shadow with continuous curvature - no rectangular clipping
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.01))
                    .shadow(
                        color: Color.black.opacity(isExpanded ? 0.45 : 0.25),
                        radius: isExpanded ? 18 : 6,
                        x: 0,
                        y: isExpanded ? 6 : 2
                    )
            )
    }
}
