import Testing
import AppKit

@MainActor private func makeWindow() -> NSWindow {
    _ = NSApplication.shared
    return NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 39),
                    styleMask: .borderless, backing: .buffered, defer: true)
}

/// The glass view, which must sit INSIDE the content view: as the content view itself, its mask
/// would also reshape the window and leave stray transparent pixels after switching back to black.
@MainActor private func glassView(_ w: NSWindow) -> NSVisualEffectView? {
    w.contentView?.subviews.first as? NSVisualEffectView
}

/// What the user actually sees: window opacity x content opacity (x glass opacity, if any).
@MainActor private func visibleOpacity(_ w: NSWindow) -> CGFloat {
    w.alphaValue * (w.contentView?.alphaValue ?? 0) * (glassView(w)?.alphaValue ?? 1)
}

@Suite @MainActor struct BarStyleTests {
    @Test func blackSquareIsOpaqueBlackView() {
        let w = makeWindow()
        BarStyle.apply(look: .black, glassIntensity: 60, radius: 0, to: w)
        #expect(w.contentView is BarView)
        #expect(w.isOpaque)
        #expect(visibleOpacity(w) == 1)
    }

    @Test func glassUsesBehindWindowBlurAtChosenStrength() throws {
        let w = makeWindow()
        BarStyle.apply(look: .glass, glassIntensity: 40, radius: 0, to: w)
        #expect(!(w.contentView is NSVisualEffectView))
        let fx = try #require(glassView(w))
        #expect(fx.blendingMode == .behindWindow)
        #expect(fx.state == .active)
        #expect(!w.isOpaque)
        #expect(abs(visibleOpacity(w) - 0.4) < 0.001)
    }

    @Test func roundedGlassIsMaskedSquareGlassIsNot() throws {
        let w = makeWindow()
        BarStyle.apply(look: .glass, glassIntensity: 100, radius: 12, to: w)
        #expect(try #require(glassView(w)).maskImage != nil)
        BarStyle.apply(look: .glass, glassIntensity: 100, radius: 0, to: w)
        #expect(try #require(glassView(w)).maskImage == nil)
    }

    @Test func switchingBackToBlackRestoresFullOpacity() {
        // Regression guard: glass strength must not leak into the black style.
        let w = makeWindow()
        BarStyle.apply(look: .glass, glassIntensity: 10, radius: 12, to: w)
        BarStyle.apply(look: .black, glassIntensity: 10, radius: 0, to: w)
        #expect(w.contentView is BarView)
        #expect(w.isOpaque)
        #expect(visibleOpacity(w) == 1)
    }

    @Test func roundedBlackCarriesRadiusToView() throws {
        let w = makeWindow()
        BarStyle.apply(look: .black, glassIntensity: 60, radius: 9, to: w)
        #expect(try #require(w.contentView as? BarView).cornerRadius == 9)
        #expect(!w.isOpaque)
    }
}
