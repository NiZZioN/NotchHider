import Testing
import Foundation

@main struct TestRunner {
    static func main() async { exit(await Testing.__swiftPMEntryPoint() as CInt) }
}
