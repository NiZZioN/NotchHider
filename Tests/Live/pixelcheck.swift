// Usage: pixelcheck <png> [x y w h]   (region in image pixels, optional)
// Reports how many visible pixels are exactly RGB 0,0,0 (display pixels off).
import AppKit
let a = CommandLine.arguments
guard a.count >= 2, let img = NSImage(contentsOfFile: a[1]),
      let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { print("cannot read image"); exit(2) }
var region = CGRect(x: 0, y: 0, width: cg.width, height: cg.height)
if a.count == 6 { region = CGRect(x: Int(a[2])!, y: Int(a[3])!, width: Int(a[4])!, height: Int(a[5])!) }
let w = cg.width, h = cg.height
var buf = [UInt8](repeating: 0, count: w * h * 4)
// Same colour space as the capture, so values are not re-mapped.
let ctx = CGContext(data: &buf, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                    space: cg.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
var opaque = 0, black = 0, transparent = 0, maxChannel: UInt8 = 0
for y in Int(region.minY)..<Int(region.maxY) { for x in Int(region.minX)..<Int(region.maxX) {
    let i = (y * w + x) * 4
    if buf[i + 3] == 0 { transparent += 1; continue }
    opaque += 1
    let m = max(buf[i], buf[i + 1], buf[i + 2]); maxChannel = max(maxChannel, m)
    if m == 0 { black += 1 }
} }
print("size \(w)x\(h) region \(Int(region.width))x\(Int(region.height)) visible=\(opaque) pureBlack=\(black) transparent=\(transparent) maxRGB=\(maxChannel)")
exit(opaque > 0 && black == opaque ? 0 : 1)
