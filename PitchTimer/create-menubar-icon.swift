#!/usr/bin/env swift

import AppKit
import Foundation

func createMenuBarIcon(size: CGSize) -> NSImage {
    let image = NSImage(size: size, flipped: false) { rect in
        guard let context = NSGraphicsContext.current?.cgContext else { return false }

        // Clear background
        context.clear(rect)

        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2 * 0.8

        // Draw simplified tick marks (only 12 ticks like a clock)
        let tickCount = 12
        let tickLength = radius * 0.15
        let tickWidth = radius * 0.08

        for i in 0..<tickCount {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(tickCount) - .pi / 2

            let startRadius = radius - tickLength
            let endRadius = radius

            let startX = center.x + cos(angle) * startRadius
            let startY = center.y + sin(angle) * startRadius
            let endX = center.x + cos(angle) * endRadius
            let endY = center.y + sin(angle) * endRadius

            context.setStrokeColor(NSColor.black.cgColor)
            context.setLineWidth(tickWidth)
            context.setLineCap(.round)

            context.move(to: CGPoint(x: startX, y: startY))
            context.addLine(to: CGPoint(x: endX, y: endY))
            context.strokePath()
        }

        // Draw a simple number in the center
        let fontSize = radius * 0.8
        let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]

        let text = "5" as NSString
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: center.x - textSize.width / 2,
            y: center.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )

        text.draw(in: textRect, withAttributes: attributes)

        return true
    }

    // Make it a template image for menu bar
    image.isTemplate = true
    return image
}

func saveImageAsPNG(_ image: NSImage, path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        print("Failed to convert image to PNG")
        return
    }

    try? pngData.write(to: URL(fileURLWithPath: path))
}

// Create menu bar icons
print("🎨 Generating menu bar icon...")

// Standard size (18x18 is typical for menu bar)
let standardImage = createMenuBarIcon(size: CGSize(width: 18, height: 18))
saveImageAsPNG(standardImage, path: "MenuBarIcon.png")
print("  ✓ Created MenuBarIcon.png (18x18)")

// Retina size
let retinaImage = createMenuBarIcon(size: CGSize(width: 36, height: 36))
saveImageAsPNG(retinaImage, path: "MenuBarIcon@2x.png")
print("  ✓ Created MenuBarIcon@2x.png (36x36)")

print("✅ Menu bar icons created!")
