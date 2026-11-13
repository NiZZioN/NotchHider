// Live harness: one strip window, restyled in place through BarStyle.apply (the same path the
// settings use). Steps are "<look>:<radius>" (e.g. black:12, glass:0). Prints "<look> <radius> <windowID>"
// after each step and waits for the
// caller to capture it; advances on each line read from stdin.
import AppKit

final class StripWindow: NSWindow {
    override func constrainFrameRect(_ f: NSRect, to s: NSScreen?) -> NSRect { f }
}

@main struct Restyle {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let rect = NSRect(x: 0, y: 400, width: 1800, height: 39)
        let w = StripWindow(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
        w.contentView = BarView(frame: NSRect(origin: .zero, size: rect.size))
        w.hasShadow = false
        BarStyle.apply(look: .black, glassIntensity: 60, radius: 0, to: w)
        w.orderFrontRegardless()
        let steps: [(BarLook, CGFloat)] = CommandLine.arguments.dropFirst().map {
            let p = $0.split(separator: ":"); return (BarLook(rawValue: String(p[0]))!, CGFloat(Double(p[1])!))
        }
        var i = 0
        func step() {
            guard i < steps.count else { exit(0) }
            BarStyle.apply(look: steps[i].0, glassIntensity: 60, radius: steps[i].1, to: w)
            w.displayIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print(steps[i].0.rawValue, steps[i].1, w.windowNumber); fflush(stdout)
                DispatchQueue.global().async {
                    _ = readLine()
                    DispatchQueue.main.async { i += 1; step() }
                }
            }
        }
        DispatchQueue.main.async { step() }
        app.run()
    }
}
