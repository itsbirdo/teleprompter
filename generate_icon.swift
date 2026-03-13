#!/usr/bin/env swift

import AppKit
import CoreGraphics

let svgPath = "svg_vector_illustration_of_a_vintage_1950s_ribbon_019ce868-990e-7d7e-9486-a98514b311ec.svg"

guard let svgImage = NSImage(contentsOfFile: svgPath) else {
    print("ERROR: Could not load SVG from \(svgPath)")
    exit(1)
}

print("Loaded SVG: \(svgImage.size)")

/// Draws the SVG inside a macOS-style rounded rect icon at a given size.
func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let s = size
    let inset = s * 0.02
    let iconRect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let cornerRadius = iconRect.width * 0.22 // macOS Big Sur+ icon radius

    // Rounded rect clip path (continuous/squircle approximation)
    let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Fill background with the SVG's dark background color
    ctx.saveGState()
    iconPath.addClip()
    NSColor(red: 0.10, green: 0.11, blue: 0.13, alpha: 1.0).setFill()
    iconPath.fill()

    // Draw the SVG centered and scaled to fit with some padding
    let padding = s * 0.01
    let drawRect = iconRect.insetBy(dx: padding, dy: padding)

    // Maintain aspect ratio
    let svgAspect = svgImage.size.width / svgImage.size.height
    let drawAspect = drawRect.width / drawRect.height
    var finalRect = drawRect

    if svgAspect > drawAspect {
        // SVG is wider — fit to width
        let newHeight = drawRect.width / svgAspect
        finalRect.origin.y += (drawRect.height - newHeight) / 2
        finalRect.size.height = newHeight
    } else {
        // SVG is taller — fit to height
        let newWidth = drawRect.height * svgAspect
        finalRect.origin.x += (drawRect.width - newWidth) / 2
        finalRect.size.width = newWidth
    }

    svgImage.draw(in: finalRect, from: .zero, operation: .sourceOver, fraction: 1.0)

    // Subtle inner border
    ctx.restoreGState()
    NSColor(white: 1.0, alpha: 0.08).setStroke()
    iconPath.lineWidth = max(1, s * 0.005)
    iconPath.stroke()

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String, size: Int) {
    let resized = NSImage(size: NSSize(width: size, height: size))
    resized.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
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

try? fm.removeItem(atPath: iconsetDir)
try! fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

// Generate at 1024 (source) then resize
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
