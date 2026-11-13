import Testing
import AppKit

/// Renders the view at 1 pixel per point into an RGBA8 bitmap.
@MainActor private func render(radius: CGFloat, size: NSSize = NSSize(width: 200, height: 40)) -> NSBitmapImageRep {
    let v = BarView(frame: NSRect(origin: .zero, size: size))
    v.cornerRadius = radius
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    v.cacheDisplay(in: v.bounds, to: rep)
    return rep
}

/// Raw RGBA bytes at (x, y) where y counts from the TOP row.
private func rgba(_ rep: NSBitmapImageRep, _ x: Int, _ y: Int) -> [UInt8] {
    let p = rep.bitmapData! + y * rep.bytesPerRow + x * 4
    return [p[0], p[1], p[2], p[3]]
}

@Suite @MainActor struct BarViewRenderTests {
    @Test func interiorIsTrueBlackAndOpaque() {
        let rep = render(radius: 12)
        #expect(rgba(rep, 100, 20) == [0, 0, 0, 255])
    }

    @Test func everyPixelHasZeroColorChannels() {
        // Only alpha may vary (anti-aliased curve); colour must be exactly 0 everywhere -> pixels off.
        let rep = render(radius: 12)
        var nonBlack = 0
        for y in 0..<rep.pixelsHigh { for x in 0..<rep.pixelsWide {
            let px = rgba(rep, x, y)
            if px[0] != 0 || px[1] != 0 || px[2] != 0 { nonBlack += 1 }
        } }
        #expect(nonBlack == 0)
    }

    @Test func roundedBottomCornersAreTransparent() {
        let rep = render(radius: 12)
        #expect(rgba(rep, 0, 39)[3] == 0)     // bottom-left
        #expect(rgba(rep, 199, 39)[3] == 0)   // bottom-right
    }

    @Test func topCornersStayBlackWhenRounded() {
        let rep = render(radius: 12)
        #expect(rgba(rep, 0, 0) == [0, 0, 0, 255])
        #expect(rgba(rep, 199, 0) == [0, 0, 0, 255])
    }

    @Test func zeroRadiusFillsBottomCorners() {
        let rep = render(radius: 0)
        #expect(rgba(rep, 0, 39) == [0, 0, 0, 255])
        #expect(rgba(rep, 199, 39) == [0, 0, 0, 255])
    }
}
