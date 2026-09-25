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
        ZStack {
            // Frosted blur
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            // Dark acrylic tint gradient
            LinearGradient(
                colors: [
                    Color(white: 0.08, opacity: 0.85),
                    Color(white: 0.03, opacity: 0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            // Ambient inner glow
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.03))

            // Directional Specular Reflection Rim
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(specularIntensity), location: 0.0),
                            .init(color: Color.white.opacity(specularIntensity * 0.4), location: 0.3),
                            .init(color: Color.white.opacity(0.08), location: 0.7),
                            .init(color: Color.white.opacity(0.02), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.0
                )
        }
        .shadow(color: Color.black.opacity(isExpanded ? 0.45 : 0.2), radius: isExpanded ? 24 : 8, y: isExpanded ? 8 : 2)
    }
}
