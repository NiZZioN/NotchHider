import Testing
import CoreGraphics

@Suite struct StripRectTests {
    @Test func notchedScreenGetsStripCoveringMenuBarHeight() {
        // MacBook display: 1800x1169 pt, menu bar ends at y=1130.
        let r = BarGeometry.stripRect(screenFrame: CGRect(x: 0, y: 0, width: 1800, height: 1169),
                                      visibleFrame: CGRect(x: 0, y: 70, width: 1800, height: 1060),
                                      notchInset: 38)
        #expect(r == CGRect(x: 0, y: 1130, width: 1800, height: 39))
    }

    @Test func screenWithoutNotchGetsNoStrip() {
        let r = BarGeometry.stripRect(screenFrame: CGRect(x: -73, y: 1169, width: 1920, height: 1080),
                                      visibleFrame: CGRect(x: -73, y: 1169, width: 1920, height: 1047),
                                      notchInset: 0)
        #expect(r == nil)
    }

    @Test func autoHiddenMenuBarFallsBackToNotchInset() {
        let r = BarGeometry.stripRect(screenFrame: CGRect(x: 0, y: 0, width: 1800, height: 1169),
                                      visibleFrame: CGRect(x: 0, y: 0, width: 1800, height: 1169),
                                      notchInset: 38)
        #expect(r == CGRect(x: 0, y: 1131, width: 1800, height: 38))
    }

    @Test func offsetScreenKeepsItsOrigin() {
        let r = BarGeometry.stripRect(screenFrame: CGRect(x: -73, y: 1169, width: 1920, height: 1080),
                                      visibleFrame: CGRect(x: -73, y: 1169, width: 1920, height: 1047),
                                      notchInset: 33)
        #expect(r == CGRect(x: -73, y: 2216, width: 1920, height: 33))
    }
}

@Suite struct CornerRadiusTests {
    @Test(arguments: [
        (radius: CGFloat(-5.0), height: CGFloat(39.0), want: CGFloat(0.0)),   // negative -> square
        (radius: CGFloat(12.0), height: CGFloat(39.0), want: CGFloat(12.0)),  // in range -> unchanged
        (radius: CGFloat(50.0), height: CGFloat(39.0), want: CGFloat(20.0)),  // capped at slider maximum
        (radius: CGFloat(15.0), height: CGFloat(10.0), want: CGFloat(10.0)),  // never taller than the strip
    ])
    func radiusIsClamped(_ c: (radius: CGFloat, height: CGFloat, want: CGFloat)) {
        #expect(BarGeometry.clampedRadius(c.radius, stripHeight: c.height) == c.want)
    }
}

@Suite struct BarPathTests {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 40)

    @Test func roundedPathCutsBottomCorners() {
        let p = BarGeometry.barPath(in: rect, cornerRadius: 10)
        #expect(!p.contains(CGPoint(x: 2, y: 2)))     // bottom-left corner cut
        #expect(!p.contains(CGPoint(x: 98, y: 2)))    // bottom-right corner cut
        #expect(p.contains(CGPoint(x: 5, y: 5)))      // inside the arc
        #expect(p.contains(CGPoint(x: 50, y: 1)))     // bottom edge middle
    }

    @Test func roundedPathKeepsTopCornersSquare() {
        let p = BarGeometry.barPath(in: rect, cornerRadius: 10)
        #expect(p.contains(CGPoint(x: 1, y: 39)))
        #expect(p.contains(CGPoint(x: 99, y: 39)))
    }

    @Test func zeroRadiusIsFullRectangle() {
        let p = BarGeometry.barPath(in: rect, cornerRadius: 0)
        #expect(p.contains(CGPoint(x: 0.5, y: 0.5)))
        #expect(p.contains(CGPoint(x: 99.5, y: 0.5)))
    }
}
