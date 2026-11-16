/// A release version like `1.2.0`, parsed from `CFBundleShortVersionString` or a `v1.2.0` tag.
public struct AppVersion: Comparable, CustomStringConvertible {
    /// The version as written, without a leading `v`.
    public let description: String
    /// Numeric components without trailing zeros, so `1.1` == `1.1.0`.
    private let key: [Int]

    public init?(_ string: String) {
        let body = string.hasPrefix("v") ? String(string.dropFirst()) : string
        // Only ASCII digits and single dots: the tag ends up in a URL, so nothing else may pass.
        let parts = body.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...4).contains(parts.count),
              parts.allSatisfy({ (1...9).contains($0.count) && $0.allSatisfy { ("0"..."9").contains($0) } })
        else { return nil }
        var numbers = parts.map { Int($0)! }
        while numbers.count > 1, numbers.last == 0 { numbers.removeLast() }
        description = body
        key = numbers
    }

    public static func == (a: AppVersion, b: AppVersion) -> Bool { a.key == b.key }
    public static func < (a: AppVersion, b: AppVersion) -> Bool { a.key.lexicographicallyPrecedes(b.key) }
}
