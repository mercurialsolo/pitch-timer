#!/usr/bin/env swift

import AppKit
import Foundation

func createTimerIcon(size: CGSize) -> NSImage {
    let image = NSImage(size: size, flipped: false) { rect in
        guard let context = NSGraphicsContext.current?.cgContext else { return false }

        // Clear background
        context.clear(rect)

        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2 * 0.85

        // Draw tick marks around the circle
        let tickCount = 60
        let tickLength = radius * 0.12
        let tickWidth = radius * 0.03

        for i in 0..<tickCount {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(tickCount) - .pi / 2

            // Make every 5th tick longer and thicker
            let isMainTick = i % 5 == 0
            let currentTickLength = isMainTick ? tickLength * 1.5 : tickLength
            let currentTickWidth = isMainTick ? tickWidth * 1.5 : tickWidth

            let startRadius = radius - currentTickLength
            let endRadius = radius

            let startX = center.x + cos(angle) * startRadius
            let startY = center.y + sin(angle) * startRadius
            let endX = center.x + cos(angle) * endRadius
            let endY = center.y + sin(angle) * endRadius

            context.setStrokeColor(NSColor.darkGray.cgColor)
            context.setLineWidth(currentTickWidth)
            context.setLineCap(.round)

            context.move(to: CGPoint(x: startX, y: startY))
            context.addLine(to: CGPoint(x: endX, y: endY))
            context.strokePath()
        }

        // Draw digital number "05"
        let fontSize = radius * 0.6
        let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]

        let text = "05" as NSString
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: center.x - textSize.width / 2,
            y: center.y - textSize.height / 2 + radius * 0.08,
            width: textSize.width,
            height: textSize.height
        )

        text.draw(in: textRect, withAttributes: attributes)

        // Draw "MIN" below the number
        let minFontSize = fontSize * 0.25
        let minFont = NSFont.systemFont(ofSize: minFontSize, weight: .medium)
        let minAttributes: [NSAttributedString.Key: Any] = [
            .font: minFont,
            .foregroundColor: NSColor.darkGray,
            .kern: 1.5
        ]

        let minText = "MIN" as NSString
        let minTextSize = minText.size(withAttributes: minAttributes)
        let minTextRect = CGRect(
            x: center.x - minTextSize.width / 2,
            y: center.y - textSize.height / 2 - minTextSize.height * 1.2,
            width: minTextSize.width,
            height: minTextSize.height
        )

        minText.draw(in: minTextRect, withAttributes: minAttributes)

        return true
    }

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

// Create icon directory
let iconsetPath = "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// Generate all required icon sizes
let sizes: [(Int, String)] = [
    (16, "16x16"),
    (32, "16x16@2x"),
    (32, "32x32"),
    (64, "32x32@2x"),
    (128, "128x128"),
    (256, "128x128@2x"),
    (256, "256x256"),
    (512, "256x256@2x"),
    (512, "512x512"),
    (1024, "512x512@2x")
]

print("🎨 Generating PitchTimer icon...")

for (size, name) in sizes {
    let image = createTimerIcon(size: CGSize(width: size, height: size))
    let filename = "\(iconsetPath)/icon_\(name).png"
    saveImageAsPNG(image, path: filename)
    print("  ✓ Created \(name)")
}

print("✅ Icon files created in \(iconsetPath)")
print("🔧 Converting to .icns...")

// Convert iconset to icns
let task = Process()
task.launchPath = "/usr/bin/iconutil"
task.arguments = ["-c", "icns", iconsetPath, "-o", "AppIcon.icns"]
task.launch()
task.waitUntilExit()

if task.terminationStatus == 0 {
    print("✅ AppIcon.icns created successfully!")

    // Clean up iconset directory
    try? FileManager.default.removeItem(atPath: iconsetPath)
    print("🧹 Cleaned up temporary files")
} else {
    print("❌ Failed to create .icns file")
}
