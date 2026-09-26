import AppKit

func generateIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // Background squircle (Apple standard corner radius ~ 22.5%)
    let cornerRadius = size * 0.225
    let squirclePath = CGPath(roundedRect: rect.insetBy(dx: size * 0.04, dy: size * 0.04),
                              cornerWidth: cornerRadius,
                              cornerHeight: cornerRadius,
                              transform: nil)

    // Dark sleek titanium gradient
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.16, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.02, green: 0.03, blue: 0.06, alpha: 1.0).cgColor
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!

    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()
    ctx.drawLinearGradient(bgGradient,
                           start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: 0, y: 0),
                           options: [])

    // Specular top highlight
    let rimColors = [
        NSColor(white: 1.0, alpha: 0.35).cgColor,
        NSColor(white: 1.0, alpha: 0.0).cgColor
    ] as CFArray
    let rimGradient = CGGradient(colorsSpace: colorSpace, colors: rimColors, locations: [0.0, 0.4])!
    ctx.drawLinearGradient(rimGradient,
                           start: CGPoint(x: size * 0.5, y: size * 0.96),
                           end: CGPoint(x: size * 0.5, y: size * 0.5),
                           options: [])
    ctx.restoreGState()

    // Outer subtle border
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.18).cgColor)
    ctx.setLineWidth(max(1.0, size * 0.015))
    ctx.strokePath()
    ctx.restoreGState()

    // Draw stylized Liquid Glass Notch in top center
    let notchW = size * 0.52
    let notchH = size * 0.22
    let notchX = (size - notchW) / 2
    let notchY = size * 0.68
    let notchRect = CGRect(x: notchX, y: notchY, width: notchW, height: notchH)
    let notchPath = CGPath(roundedRect: notchRect,
                           cornerWidth: notchH * 0.45,
                           cornerHeight: notchH * 0.45,
                           transform: nil)

    ctx.saveGState()
    ctx.addPath(notchPath)
    ctx.setFillColor(NSColor(calibratedRed: 0.04, green: 0.06, blue: 0.10, alpha: 0.95).cgColor)
    ctx.fillPath()

    // Emerald LED dot
    let ledRadius = size * 0.02
    let ledRect = CGRect(x: notchX + notchW * 0.22 - ledRadius,
                         y: notchY + notchH * 0.5 - ledRadius,
                         width: ledRadius * 2,
                         height: ledRadius * 2)
    ctx.setFillColor(NSColor(calibratedRed: 0.2, green: 0.9, blue: 0.5, alpha: 1.0).cgColor)
    ctx.fillEllipse(in: ledRect)

    // Camera lens dot
    let camRadius = size * 0.028
    let camRect = CGRect(x: notchX + notchW * 0.5 - camRadius,
                         y: notchY + notchH * 0.5 - camRadius,
                         width: camRadius * 2,
                         height: camRadius * 2)
    ctx.setFillColor(NSColor(calibratedRed: 0.01, green: 0.02, blue: 0.03, alpha: 1.0).cgColor)
    ctx.fillEllipse(in: camRect)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.25).cgColor)
    ctx.setLineWidth(1.0)
    ctx.strokeEllipse(in: camRect)

    // Inner camera core
    let coreRadius = camRadius * 0.45
    let coreRect = CGRect(x: notchX + notchW * 0.5 - coreRadius,
                          y: notchY + notchH * 0.5 - coreRadius,
                          width: coreRadius * 2,
                          height: coreRadius * 2)
    ctx.setFillColor(NSColor(calibratedRed: 0.1, green: 0.2, blue: 0.4, alpha: 0.9).cgColor)
    ctx.fillEllipse(in: coreRect)

    // Notch rim stroke
    ctx.addPath(notchPath)
    ctx.setStrokeColor(NSColor(calibratedRed: 0.3, green: 0.7, blue: 1.0, alpha: 0.45).cgColor)
    ctx.setLineWidth(max(1.0, size * 0.012))
    ctx.strokePath()
    ctx.restoreGState()

    // 6-app tactile grid representation below notch
    let gridY = size * 0.18
    let gridW = size * 0.64
    let gridH = size * 0.40
    let startX = (size - gridW) / 2
    let cols = 3
    let rows = 2
    let padX = size * 0.03
    let padY = size * 0.03
    let tileW = (gridW - padX * CGFloat(cols - 1)) / CGFloat(cols)
    let tileH = (gridH - padY * CGFloat(rows - 1)) / CGFloat(rows)

    let tileColors = [
        NSColor(calibratedRed: 0.0, green: 0.6, blue: 1.0, alpha: 0.7), // VS Code
        NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.25, alpha: 0.8), // Terminal
        NSColor(calibratedRed: 0.1, green: 0.7, blue: 0.9, alpha: 0.75), // Safari
        NSColor(calibratedRed: 0.2, green: 0.5, blue: 0.95, alpha: 0.8), // Finder
        NSColor(calibratedRed: 0.95, green: 0.25, blue: 0.4, alpha: 0.8), // Music
        NSColor(calibratedRed: 0.6, green: 0.65, blue: 0.7, alpha: 0.7) // Settings
    ]

    var idx = 0
    for r in 0..<rows {
        for c in 0..<cols {
            let tx = startX + CGFloat(c) * (tileW + padX)
            let ty = gridY + CGFloat(rows - 1 - r) * (tileH + padY)
            let tileRect = CGRect(x: tx, y: ty, width: tileW, height: tileH)
            let tilePath = CGPath(roundedRect: tileRect,
                                  cornerWidth: tileH * 0.32,
                                  cornerHeight: tileH * 0.32,
                                  transform: nil)
            ctx.saveGState()
            ctx.addPath(tilePath)
            ctx.setFillColor(tileColors[idx % tileColors.count].cgColor)
            ctx.fillPath()

            ctx.addPath(tilePath)
            ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.3).cgColor)
            ctx.setLineWidth(max(1.0, size * 0.008))
            ctx.strokePath()
            ctx.restoreGState()
            idx += 1
        }
    }

    img.unlockFocus()
    return img
}

func savePNG(image: NSImage, path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: URL(fileURLWithPath: path))
}

let iconsetDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, s) in sizes {
    let img = generateIcon(size: s)
    savePNG(image: img, path: "\(iconsetDir)/\(name)")
}
print("Generated iconset in \(iconsetDir)")
