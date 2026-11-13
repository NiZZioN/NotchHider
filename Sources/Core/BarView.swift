import AppKit

/// Fills its bounds with pure black (RGB 0,0,0 = pixels off), optionally rounding the bottom corners.
public final class BarView: NSView {
    public var cornerRadius: CGFloat = 0 { didSet { needsDisplay = true } }

    public override var isOpaque: Bool { cornerRadius <= 0 }

    public override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        // No ctx.clear() here: clearing the window backing makes the window server dither the
        // black (~1/3 of pixels end up at 1/255). AppKit already hands non-opaque views a clear buffer.
        ctx.addPath(BarGeometry.barPath(in: bounds, cornerRadius: cornerRadius))
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        ctx.fillPath()
    }
}
