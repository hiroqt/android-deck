import Foundation

public struct GlassAppearanceSettings: Codable, Equatable {
    public var blurMaterial: String // "hud", "ultraThin", "thin"
    public var specularIntensity: Double // 0.0 ... 1.0
    public var ambientBacklightEnabled: Bool
    public var cornerRadius: Double

    public init(
        blurMaterial: String = "hud",
        specularIntensity: Double = 0.45,
        ambientBacklightEnabled: Bool = true,
        cornerRadius: Double = 24.0
    ) {
        self.blurMaterial = blurMaterial
        self.specularIntensity = specularIntensity
        self.ambientBacklightEnabled = ambientBacklightEnabled
        self.cornerRadius = cornerRadius
    }
}
