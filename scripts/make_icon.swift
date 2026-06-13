import AppKit

let size = 1024.0
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("no ctx") }

func color(_ hex: UInt) -> CGColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF)/255,
            green: CGFloat((hex >> 8) & 0xFF)/255,
            blue: CGFloat(hex & 0xFF)/255, alpha: 1).cgColor
}

// Background amber gradient (135°)
let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                      colors: [color(0xF5A623), color(0xFFC107)] as CFArray,
                      locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: size),
                       end: CGPoint(x: size, y: 0), options: [])

// Helper rounded rect path
func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

// A tilted white card in the center
ctx.saveGState()
ctx.translateBy(x: size/2, y: size/2)
ctx.rotate(by: -8 * .pi / 180)

let cardW = 430.0, cardH = 600.0
let cardRect = CGRect(x: -cardW/2, y: -cardH/2, width: cardW, height: cardH)

// Soft shadow
ctx.setShadow(offset: CGSize(width: 0, height: -24), blur: 60,
              color: NSColor.black.withAlphaComponent(0.22).cgColor)
ctx.addPath(roundedRect(cardRect, radius: 64))
ctx.setFillColor(NSColor.white.cgColor)
ctx.fillPath()
ctx.setShadow(offset: .zero, blur: 0, color: nil)

// Inner amber header band on the card
let band = CGRect(x: cardRect.minX, y: cardRect.maxY - 150, width: cardW, height: 150)
ctx.saveGState()
ctx.addPath(roundedRect(cardRect, radius: 64))
ctx.clip()
ctx.setFillColor(color(0xFFDDB4))
ctx.fill(band)
ctx.restoreGState()

// Upward value trend line across the card
let line = CGMutablePath()
let pts = [CGPoint(x: -150, y: -120), CGPoint(x: -70, y: -20),
           CGPoint(x: 10, y: -70), CGPoint(x: 90, y: 90),
           CGPoint(x: 165, y: 40)]
line.move(to: pts[0])
for p in pts.dropFirst() { line.addLine(to: p) }
ctx.addPath(line)
ctx.setStrokeColor(color(0x2E9E5B))
ctx.setLineWidth(34)
ctx.setLineJoin(.round)
ctx.setLineCap(.round)
ctx.strokePath()

// End dot on the trend line
ctx.setFillColor(color(0x2E9E5B))
ctx.fillEllipse(in: CGRect(x: pts.last!.x - 26, y: pts.last!.y - 26, width: 52, height: 52))
ctx.setFillColor(NSColor.white.cgColor)
ctx.fillEllipse(in: CGRect(x: pts.last!.x - 12, y: pts.last!.y - 12, width: 24, height: 24))

ctx.restoreGState()

image.unlockFocus()

// Export PNG
guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("encode failed")
}
let out = CommandLine.arguments[1]
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
