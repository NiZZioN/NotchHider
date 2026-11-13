import AppKit

public enum BarStyle {
    /// Styles a strip window. Called at creation and on every settings change.
    /// Always installs a fresh content view: re-using a view whose window switched between opaque
    /// and transparent makes the window server dither the black (verified by verify-restyle.sh).
    public static func apply(look: BarLook, glassIntensity: Double, radius: CGFloat, to window: NSWindow) {
        let size = window.frame.size
        window.alphaValue = 1
        switch look {
        case .black:
            window.isOpaque = radius == 0
            window.backgroundColor = radius == 0 ? .black : .clear
            let view = BarView(frame: NSRect(origin: .zero, size: size))
            view.cornerRadius = radius
            window.contentView = view
        case .glass:
            window.isOpaque = false
            window.backgroundColor = .clear
            let fx = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
            fx.material = .hudWindow
            fx.blendingMode = .behindWindow
            fx.state = .active
            fx.maskImage = radius > 0 ? maskImage(size: size, radius: radius) : nil
            fx.alphaValue = CGFloat(min(max(glassIntensity, 1), 100) / 100)
            fx.autoresizingMask = [.width, .height]
            // Nested, not the content view: a content-view effect view's mask also reshapes the
            // window, leaving stray transparent pixels after switching back to black.
            let container = NSView(frame: NSRect(origin: .zero, size: size))
            container.addSubview(fx)
            window.contentView = container
        }
    }

    private static func maskImage(size: NSSize, radius: CGFloat) -> NSImage {
        NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.addPath(BarGeometry.barPath(in: rect, cornerRadius: radius))
            ctx.setFillColor(CGColor(gray: 0, alpha: 1))
            ctx.fillPath()
            return true
        }
    }
}
