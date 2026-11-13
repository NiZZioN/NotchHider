import CoreGraphics

public enum BarGeometry {
    /// Largest corner radius offered by the slider, in points.
    public static let maxCornerRadius: CGFloat = 20

    /// Rect (in global AppKit coordinates) of the black strip for a screen, or nil if it has no notch.
    public static func stripRect(screenFrame: CGRect, visibleFrame: CGRect, notchInset: CGFloat) -> CGRect? {
        guard notchInset > 0 else { return nil }
        var height = screenFrame.maxY - visibleFrame.maxY
        if height <= 0 { height = notchInset }          // menu bar set to auto-hide
        return CGRect(x: screenFrame.minX, y: screenFrame.maxY - height,
                      width: screenFrame.width, height: height)
    }

    public static func clampedRadius(_ radius: CGFloat, stripHeight: CGFloat) -> CGFloat {
        max(0, min(radius, maxCornerRadius, stripHeight))
    }

    /// Strip outline: square top corners (screen edge), rounded bottom corners.
    public static func barPath(in rect: CGRect, cornerRadius: CGFloat) -> CGPath {
        let r = max(0, min(cornerRadius, rect.height, rect.width / 2))
        let p = CGMutablePath()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                 tangent2End: CGPoint(x: rect.minX, y: rect.minY), radius: r)
        p.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                 tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: r)
        p.closeSubpath()
        return p
    }
}
