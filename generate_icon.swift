#!/usr/bin/env swift

import AppKit
import CoreGraphics

/// Draws the Teleprompter app icon at a given size.
func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let s = size // shorthand
    let inset: CGFloat = s * 0.08
    let cornerRadius: CGFloat = s * 0.22

    // --- Background: dark rounded rect with subtle gradient ---
    let bgRect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Gradient: deep charcoal to near-black
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        CGColor(red: 0.14, green: 0.14, blue: 0.18, alpha: 1.0),
        CGColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
        ctx.saveGState()
        ctx.addPath(bgPath)
        ctx.clip()
        ctx.drawLinearGradient(gradient,
            start: CGPoint(x: s / 2, y: s - inset),
            end: CGPoint(x: s / 2, y: inset),
            options: [])
        ctx.restoreGState()
    }

    // Subtle inner border
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.08))
    ctx.setLineWidth(s * 0.01)
    ctx.strokePath()
    ctx.restoreGState()

    // --- Text lines (teleprompter motif) ---
    let lineColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.12)
    let activeLineColor = CGColor(red: 0.42, green: 0.36, blue: 0.91, alpha: 0.5) // purple hint
    let lineHeight: CGFloat = s * 0.035
    let lineSpacing: CGFloat = s * 0.065
    let lineStartY: CGFloat = s * 0.62
    let lineX: CGFloat = s * 0.22
    let lineWidths: [CGFloat] = [0.56, 0.50, 0.44, 0.38, 0.30]

    for (i, width) in lineWidths.enumerated() {
        let y = lineStartY - CGFloat(i) * lineSpacing
        let rect = CGRect(x: lineX, y: y, width: s * width, height: lineHeight)
        let path = CGPath(roundedRect: rect, cornerWidth: lineHeight / 2, cornerHeight: lineHeight / 2, transform: nil)

        ctx.saveGState()
        ctx.addPath(path)
        ctx.setFillColor(i == 0 ? activeLineColor : lineColor)
        ctx.fillPath()
        ctx.restoreGState()
    }

    // --- Central play/voice symbol ---
    // A rounded triangle (play) merged with a small voice wave
    let centerX: CGFloat = s * 0.5
    let centerY: CGFloat = s * 0.48
    let triSize: CGFloat = s * 0.2

    // Glow behind the symbol
    ctx.saveGState()
    let glowColor = CGColor(red: 0.42, green: 0.36, blue: 0.91, alpha: 0.3)
    ctx.setShadow(offset: .zero, blur: s * 0.08, color: glowColor)

    // Play triangle
    let tri = CGMutablePath()
    tri.move(to: CGPoint(x: centerX - triSize * 0.35, y: centerY + triSize * 0.45))
    tri.addLine(to: CGPoint(x: centerX - triSize * 0.35, y: centerY - triSize * 0.45))
    tri.addLine(to: CGPoint(x: centerX + triSize * 0.45, y: centerY))
    tri.closeSubpath()

    // Purple gradient fill for triangle
    let triColors = [
        CGColor(red: 0.42, green: 0.36, blue: 0.91, alpha: 1.0),
        CGColor(red: 0.35, green: 0.30, blue: 0.83, alpha: 1.0)
    ] as CFArray
    if let triGrad = CGGradient(colorsSpace: colorSpace, colors: triColors, locations: [0.0, 1.0]) {
        ctx.saveGState()
        ctx.addPath(tri)
        ctx.clip()
        ctx.drawLinearGradient(triGrad,
            start: CGPoint(x: centerX, y: centerY + triSize * 0.5),
            end: CGPoint(x: centerX, y: centerY - triSize * 0.5),
            options: [])
        ctx.restoreGState()
    }
    ctx.restoreGState()

    // Voice wave arcs (right side of play button)
    let arcX = centerX + triSize * 0.55
    let arcRadii: [CGFloat] = [triSize * 0.3, triSize * 0.5, triSize * 0.7]
    let arcAlphas: [CGFloat] = [0.6, 0.4, 0.2]

    for (i, radius) in arcRadii.enumerated() {
        ctx.saveGState()
        ctx.setStrokeColor(CGColor(red: 0.42, green: 0.36, blue: 0.91, alpha: arcAlphas[i]))
        ctx.setLineWidth(s * 0.018)
        ctx.setLineCap(.round)
        ctx.addArc(center: CGPoint(x: arcX, y: centerY),
                   radius: radius,
                   startAngle: -.pi / 4,
                   endAngle: .pi / 4,
                   clockwise: true)
        ctx.strokePath()
        ctx.restoreGState()
    }

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String, size: Int) {
    let resized = NSImage(size: NSSize(width: size, height: size))
    resized.lockFocus()
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    resized.unlockFocus()

    guard let tiff = resized.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for size \(size)")
        return
    }

    do {
        try png.write(to: URL(fileURLWithPath: path))
    } catch {
        print("Failed to write \(path): \(error)")
    }
}

// --- Main ---

let iconsetDir = "build/Teleprompter.iconset"
let fm = FileManager.default

// Remove old iconset
try? fm.removeItem(atPath: iconsetDir)
try! fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

// Generate at 1024 (source) then resize for all required sizes
let source = drawIcon(size: 1024)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, size) in sizes {
    savePNG(source, to: "\(iconsetDir)/\(name)", size: size)
}

print("Icon PNGs generated in \(iconsetDir)")
