import AppKit
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first ?? "background.png"
let appName = CommandLine.arguments.dropFirst(2).first ?? "NotchMeter"

let size = NSSize(width: 660, height: 420)
let image = NSImage(size: size)

func drawText(_ text: String, at point: NSPoint, font: NSFont, color: NSColor, alignment: NSTextAlignment = .center, width: CGFloat = 560) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSString(string: text).draw(in: NSRect(x: point.x, y: point.y, width: width, height: 42), withAttributes: attributes)
}

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)
NSColor.black.setFill()
rect.fill()

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.02, green: 0.03, blue: 0.04, alpha: 1),
    NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 1)
])
gradient?.draw(in: rect, angle: 90)

NSColor(calibratedWhite: 1, alpha: 0.08).setStroke()
let notch = NSBezierPath(roundedRect: NSRect(x: 220, y: 356, width: 220, height: 42), xRadius: 18, yRadius: 18)
notch.lineWidth = 1
NSColor.black.setFill()
notch.fill()
notch.stroke()

drawText(
    "Drag \(appName) to Applications",
    at: NSPoint(x: 50, y: 306),
    font: NSFont.systemFont(ofSize: 24, weight: .semibold),
    color: NSColor(calibratedWhite: 0.94, alpha: 1)
)
drawText(
    "把应用拖到 Applications 文件夹完成安装",
    at: NSPoint(x: 50, y: 274),
    font: NSFont.systemFont(ofSize: 15, weight: .medium),
    color: NSColor(calibratedWhite: 0.62, alpha: 1)
)

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 270, y: 190))
arrow.curve(to: NSPoint(x: 390, y: 190), controlPoint1: NSPoint(x: 308, y: 224), controlPoint2: NSPoint(x: 352, y: 224))
arrow.lineWidth = 7
NSColor(calibratedRed: 0.48, green: 0.94, blue: 0.25, alpha: 0.9).setStroke()
arrow.stroke()

let head = NSBezierPath()
head.move(to: NSPoint(x: 390, y: 190))
head.line(to: NSPoint(x: 364, y: 207))
head.move(to: NSPoint(x: 390, y: 190))
head.line(to: NSPoint(x: 364, y: 173))
head.lineWidth = 7
head.lineCapStyle = .round
head.lineJoinStyle = .round
head.stroke()

NSColor(calibratedWhite: 1, alpha: 0.08).setStroke()
NSColor(calibratedWhite: 1, alpha: 0.035).setFill()
for x in stride(from: CGFloat(70), through: 590, by: 26) {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: x, y: 64))
    path.line(to: NSPoint(x: x, y: 250))
    path.lineWidth = 1
    path.stroke()
}

drawText(
    "Open from Applications after copying",
    at: NSPoint(x: 50, y: 38),
    font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
    color: NSColor(calibratedWhite: 0.44, alpha: 1)
)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let data = rep.representation(using: .png, properties: [.compressionFactor: 0.95]) else {
    fputs("Could not render DMG background\n", stderr)
    exit(1)
}

try data.write(to: URL(fileURLWithPath: outputPath))
