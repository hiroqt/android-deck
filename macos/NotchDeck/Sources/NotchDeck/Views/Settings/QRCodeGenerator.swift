import Foundation
import CoreImage
import AppKit

/// Generates crisp, high-contrast QR code images for display in SwiftUI on macOS.
public enum QRCodeGenerator {
    private static let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])

    /// Generates an NSImage containing a QR code for the given string.
    /// - Parameters:
    ///   - string: The URL or payload string to encode.
    ///   - size: The target width and height in points.
    ///   - correctionLevel: Error correction capability ("L", "M", "Q", "H"). Defaults to "M".
    /// - Returns: A non-interpolated, sharp NSImage or nil if encoding fails.
    public static func generate(
        from string: String,
        size: CGFloat = 160,
        correctionLevel: String = "M"
    ) -> NSImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")

        guard let outputCI = filter.outputImage else {
            return nil
        }

        // Scale up using nearest-neighbor / crisp point sampling
        let scale = size / max(outputCI.extent.size.width, 1.0)
        let transformed = outputCI.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
    }
}
