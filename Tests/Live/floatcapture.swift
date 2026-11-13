// Usage: floatcapture <windowID> [--expect-transparent]
// Captures one window via ScreenCaptureKit as 16-bit float RGBA (no 8-bit conversion/dither)
// and reports whether every visible pixel is exactly 0.0 in R, G and B.
import ScreenCaptureKit
import CoreVideo
import AppKit

@main struct FloatCapture {
    static func main() async throws {
        _ = NSApplication.shared  // initialise the window-server connection
        let wid = CGWindowID(CommandLine.arguments[1])!
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        guard let win = content.windows.first(where: { $0.windowID == wid }) else { print("window not found"); exit(2) }
        let cfg = SCStreamConfiguration()
        cfg.pixelFormat = kCVPixelFormatType_64RGBAHalf
        cfg.width = Int(win.frame.width * 2); cfg.height = Int(win.frame.height * 2)
        cfg.showsCursor = false
        cfg.ignoreShadowsSingleWindow = true
        let filter = SCContentFilter(desktopIndependentWindow: win)
        let sample = try await SCScreenshotManager.captureSampleBuffer(contentFilter: filter, configuration: cfg)
        let pb = sample.imageBuffer!
        CVPixelBufferLockBaseAddress(pb, .readOnly); defer { CVPixelBufferUnlockBaseAddress(pb, .readOnly) }
        let w = CVPixelBufferGetWidth(pb), h = CVPixelBufferGetHeight(pb), rb = CVPixelBufferGetBytesPerRow(pb)
        let base = CVPixelBufferGetBaseAddress(pb)!
        var visible = 0, black = 0, transparent = 0; var maxV: Float = 0; var transparentAt: [String] = []
        for y in 0..<h {
            let row = (base + y * rb).assumingMemoryBound(to: Float16.self)
            for x in 0..<w {
                let r = Float(row[x*4]), g = Float(row[x*4+1]), b = Float(row[x*4+2]), a = Float(row[x*4+3])
                if a == 0 { transparent += 1; if transparentAt.count < 5 { transparentAt.append("(\(x),\(y))") }; continue }
                visible += 1
                let m = max(r, g, b); maxV = max(maxV, m)
                if m == 0 { black += 1 }
            }
        }
        print("float16 \(w)x\(h) visible=\(visible) exactZero=\(black) transparent=\(transparent) maxRGB=\(maxV)" + (transparent > 0 && transparent < 5 ? " transparentAt=\(transparentAt)" : ""))
        let wantTransparent = CommandLine.arguments.contains("--expect-transparent")
        let ok = visible > 0 && black == visible && (wantTransparent ? transparent > 0 : transparent == 0)
        exit(ok ? 0 : 1)
    }
}
