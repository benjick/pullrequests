#!/usr/bin/env swift
// Generates AppIcon.icns — a pull request icon on a rounded-rect background
import AppKit

func drawIcon(size: CGFloat) -> NSImage {
    NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        // Background: rounded rect with a purple-blue gradient
        let cornerRadius = size * 0.22
        let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.02, dy: size * 0.02),
                                   xRadius: cornerRadius, yRadius: cornerRadius)

        let topColor = NSColor(calibratedRed: 0.40, green: 0.35, blue: 0.90, alpha: 1.0)
        let bottomColor = NSColor(calibratedRed: 0.25, green: 0.20, blue: 0.70, alpha: 1.0)
        let gradient = NSGradient(starting: bottomColor, ending: topColor)!
        gradient.draw(in: bgPath, angle: 90)

        let white = NSColor.white

        // Pull request icon layout:
        //   Two vertical lines (source branch + target branch)
        //   Source line curves into target
        //   Circle at top of source (open circle — the "from" commit)
        //   Circle at bottom of target (filled — the base)
        //   Arrow/merge indicator at top of target

        let cx = size * 0.50
        let leftX = cx - size * 0.14
        let rightX = cx + size * 0.14

        let topY = size * 0.78
        let bottomY = size * 0.22
        let midY = (topY + bottomY) / 2

        let lineWidth = size * 0.045
        let circleRadius = size * 0.065

        // --- Target branch (right vertical line) ---
        white.setStroke()
        let targetLine = NSBezierPath()
        targetLine.move(to: NSPoint(x: rightX, y: bottomY + circleRadius))
        targetLine.line(to: NSPoint(x: rightX, y: topY - circleRadius))
        targetLine.lineWidth = lineWidth
        targetLine.lineCapStyle = .round
        targetLine.stroke()

        // --- Source branch: starts at top-left circle, curves right to merge into target ---
        let sourceLine = NSBezierPath()
        sourceLine.move(to: NSPoint(x: leftX, y: topY - circleRadius))
        // Curve from left down to merge point on right line
        sourceLine.curve(to: NSPoint(x: rightX, y: midY),
                         controlPoint1: NSPoint(x: leftX, y: midY + size * 0.06),
                         controlPoint2: NSPoint(x: rightX - size * 0.01, y: midY + size * 0.12))
        sourceLine.lineWidth = lineWidth
        sourceLine.lineCapStyle = .round
        sourceLine.stroke()

        // --- Circles ---

        // Top-left circle (source — open/hollow)
        let srcCircle = NSBezierPath(ovalIn: NSRect(
            x: leftX - circleRadius, y: topY - circleRadius,
            width: circleRadius * 2, height: circleRadius * 2))
        white.setFill()
        srcCircle.fill()
        // Punch out interior for hollow look
        let srcInner = NSBezierPath(ovalIn: NSRect(
            x: leftX - circleRadius + lineWidth,
            y: topY - circleRadius + lineWidth,
            width: (circleRadius - lineWidth) * 2,
            height: (circleRadius - lineWidth) * 2))
        // Draw background color inside to make it look hollow
        let bgFill = NSColor(calibratedRed: 0.33, green: 0.28, blue: 0.80, alpha: 1.0)
        bgFill.setFill()
        srcInner.fill()

        // Bottom-right circle (target/base — filled)
        let tgtCircle = NSBezierPath(ovalIn: NSRect(
            x: rightX - circleRadius, y: bottomY - circleRadius,
            width: circleRadius * 2, height: circleRadius * 2))
        white.setFill()
        tgtCircle.fill()

        // Top-right circle (target head — filled, with a small merge arrow)
        let mergeCircle = NSBezierPath(ovalIn: NSRect(
            x: rightX - circleRadius, y: topY - circleRadius,
            width: circleRadius * 2, height: circleRadius * 2))
        white.setFill()
        mergeCircle.fill()


        return true
    }
}

// Generate all required sizes for .icns
let sizes: [(CGFloat, String)] = [
    (16, "icon_16x16"),
    (32, "icon_16x16@2x"),
    (32, "icon_32x32"),
    (64, "icon_32x32@2x"),
    (128, "icon_128x128"),
    (256, "icon_128x128@2x"),
    (256, "icon_256x256"),
    (512, "icon_256x256@2x"),
    (512, "icon_512x512"),
    (1024, "icon_512x512@2x"),
]

// Create temporary iconset directory
let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: tempDir)
try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

for (size, name) in sizes {
    let image = drawIcon(size: size)
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create \(name)")
        continue
    }
    let fileURL = tempDir.appendingPathComponent("\(name).png")
    try pngData.write(to: fileURL)
}

// Convert iconset to icns using iconutil
let outputPath = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "PullRequests/Resources/AppIcon.icns")

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", tempDir.path, "-o", outputPath.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("Icon generated at: \(outputPath.path)")
} else {
    print("iconutil failed with status \(process.terminationStatus)")
    exit(1)
}

// Cleanup
try? FileManager.default.removeItem(at: tempDir)
