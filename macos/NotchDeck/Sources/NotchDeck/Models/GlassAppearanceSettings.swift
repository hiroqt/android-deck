import Foundation

public struct GlassAppearanceSettings: Codable, Equatable {
    public var blurMaterial: String // "hud", "ultraThin", "thin"
    public var specularIntensity: Double // 0.0 ... 1.0
    public var ambientBacklightEnabled: Bool
    public var cornerRadius: Double
    public var glassTintOpacity: Double // 0.30 ... 0.95

    public init(
        blurMaterial: String = "hud",
        specularIntensity: Double = 0.45,
        ambientBacklightEnabled: Bool = true,
        cornerRadius: Double = 24.0,
        glassTintOpacity: Double = 0.72
    ) {
        self.blurMaterial = blurMaterial
        self.specularIntensity = specularIntensity
        self.ambientBacklightEnabled = ambientBacklightEnabled
        self.cornerRadius = cornerRadius
        self.glassTintOpacity = glassTintOpacity
    }

    public enum CodingKeys: String, CodingKey {
        case blurMaterial
        case specularIntensity
        case ambientBacklightEnabled
        case cornerRadius
        case glassTintOpacity
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.blurMaterial = try container.decodeIfPresent(String.self, forKey: .blurMaterial) ?? "hud"
        self.specularIntensity = try container.decodeIfPresent(Double.self, forKey: .specularIntensity) ?? 0.45
        self.ambientBacklightEnabled = try container.decodeIfPresent(Bool.self, forKey: .ambientBacklightEnabled) ?? true
        self.cornerRadius = try container.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 24.0
        self.glassTintOpacity = try container.decodeIfPresent(Double.self, forKey: .glassTintOpacity) ?? 0.72
    }
}
