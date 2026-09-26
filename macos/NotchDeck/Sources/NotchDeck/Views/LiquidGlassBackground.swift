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
    public let edge: NotchEdge
    public let cornerRadius: CGFloat
    public let curlRadius: CGFloat
    public let specularIntensity: Double
    public let isExpanded: Bool
    public var stretchDistance: CGFloat
    public var lateralOffset: CGFloat
    public var isDetached: Bool
    public var glassTintOpacity: Double
    public var ambientBacklightEnabled: Bool

    public init(
        edge: NotchEdge = .top,
        cornerRadius: CGFloat = 20.0,
        curlRadius: CGFloat = 16.0,
        specularIntensity: Double = 0.45,
        isExpanded: Bool = true,
        stretchDistance: CGFloat = 0.0,
        lateralOffset: CGFloat = 0.0,
        isDetached: Bool = false,
        glassTintOpacity: Double = 0.72,
        ambientBacklightEnabled: Bool = true
    ) {
        self.edge = edge
        self.cornerRadius = cornerRadius
        self.curlRadius = curlRadius
        self.specularIntensity = specularIntensity
        self.isExpanded = isExpanded
        self.stretchDistance = stretchDistance
        self.lateralOffset = lateralOffset
        self.isDetached = isDetached
        self.glassTintOpacity = glassTintOpacity
        self.ambientBacklightEnabled = ambientBacklightEnabled
    }

    public init(
        cornerRadius: CGFloat = 24.0,
        specularIntensity: Double = 0.45,
        isExpanded: Bool = true
    ) {
        self.edge = .top
        self.cornerRadius = cornerRadius
        self.curlRadius = 16.0
        self.specularIntensity = specularIntensity
        self.isExpanded = isExpanded
        self.stretchDistance = 0.0
        self.lateralOffset = 0.0
        self.isDetached = false
        self.glassTintOpacity = 0.72
        self.ambientBacklightEnabled = true
    }

    public init(
        settings: GlassAppearanceSettings,
        edge: NotchEdge = .top,
        isExpanded: Bool = true
    ) {
        self.edge = edge
        self.cornerRadius = CGFloat(settings.cornerRadius)
        self.curlRadius = 16.0
        self.specularIntensity = settings.specularIntensity
        self.isExpanded = isExpanded
        self.stretchDistance = 0.0
        self.lateralOffset = 0.0
        self.isDetached = false
        self.glassTintOpacity = settings.glassTintOpacity
        self.ambientBacklightEnabled = settings.ambientBacklightEnabled
    }

    private var shape: LiquidPullShape {
        LiquidPullShape(
            edge: edge,
            stretchDistance: stretchDistance,
            lateralOffset: lateralOffset,
            isDetached: isDetached,
            cornerRadius: cornerRadius
        )
    }

    private var gradientStartPoint: UnitPoint {
        switch edge {
        case .top: return .bottom
        case .right: return .leading
        case .left: return .trailing
        }
    }

    private var gradientEndPoint: UnitPoint {
        switch edge {
        case .top: return .top
        case .right: return .trailing
        case .left: return .leading
        }
    }

    private var shadowOffsetX: CGFloat {
        switch edge {
        case .top: return 0
        case .right: return isExpanded ? -8 : -3
        case .left: return isExpanded ? 8 : 3
        }
    }

    private var shadowOffsetY: CGFloat {
        switch edge {
        case .top: return isExpanded ? 6 : 2
        case .right, .left: return 0
        }
    }

    public var body: some View {
        shape
            .fill(.ultraThinMaterial)
            .overlay(
                // Dynamic acrylic tint gradient for deep obsidian-glass look
                LinearGradient(
                    colors: [
                        Color(white: 0.14, opacity: max(0.10, glassTintOpacity * 0.90)),
                        Color(white: 0.04, opacity: max(0.15, glassTintOpacity))
                    ],
                    startPoint: gradientStartPoint,
                    endPoint: gradientEndPoint
                )
                .clipShape(shape)
            )
            .overlay(
                // Ambient inner sheen
                shape
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.08 * (specularIntensity + 0.3)), location: 0.0),
                                .init(color: Color.clear, location: 0.35)
                            ],
                            startPoint: gradientStartPoint,
                            endPoint: gradientEndPoint
                        )
                    )
            )
            .overlay(
                // Directional Specular Reflection Rim
                shape
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(specularIntensity), location: 0.0),
                                .init(color: Color.white.opacity(specularIntensity * 0.45), location: 0.25),
                                .init(color: Color.white.opacity(0.08 * specularIntensity), location: 0.65),
                                .init(color: Color.clear, location: 0.90)
                            ],
                            startPoint: gradientStartPoint,
                            endPoint: gradientEndPoint
                        ),
                        lineWidth: 1.0
                    )
            )
            .background(
                // Ambient backlight glow aura
                Group {
                    if ambientBacklightEnabled {
                        shape
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.cyan.opacity(0.35 * specularIntensity), location: 0.0),
                                        .init(color: Color.blue.opacity(0.20 * specularIntensity), location: 0.35),
                                        .init(color: Color.clear, location: 0.75)
                                    ],
                                    startPoint: gradientStartPoint,
                                    endPoint: gradientEndPoint
                                ),
                                lineWidth: 2.5
                            )
                            .blur(radius: isExpanded ? 10 : 5)
                    }
                }
            )
            .background(
                // Shape-matched drop shadow with continuous curvature
                shape
                    .fill(Color.black.opacity(0.01))
                    .shadow(
                        color: Color.black.opacity(isExpanded ? 0.45 : 0.25),
                        radius: isExpanded ? 18 : 6,
                        x: shadowOffsetX,
                        y: shadowOffsetY
                    )
            )
    }
}
