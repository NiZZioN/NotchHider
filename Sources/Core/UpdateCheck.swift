import Foundation

public enum UpdateResult: Equatable {
    case upToDate
    case available(AppVersion)
    case failed(String)
}

/// Asks GitHub for the latest release and remembers the answer in UserDefaults.
/// Notify only: it never downloads or installs anything.
public final class UpdateCheck {
    private let current: AppVersion?
    private let defaults: UserDefaults
    private let now: () -> Date
    private let fetch: () async throws -> Data

    public init(currentVersion: String, defaults: UserDefaults = .standard,
                now: @escaping () -> Date = Date.init, fetch: @escaping () async throws -> Data) {
        self.current = AppVersion(currentVersion)
        self.defaults = defaults
        self.now = now
        self.fetch = fetch
    }

    public static let interval: TimeInterval = 24 * 3600
    public static let latestReleaseAPI = URL(string: "https://api.github.com/repos/NiZZioN/NotchHider/releases/latest")!

    /// Built from a validated version (digits and dots only), never from the response's `html_url`,
    /// so a tampered response can't make the app open an arbitrary page.
    public static func releasePage(for version: AppVersion) -> URL {
        URL(string: "https://github.com/NiZZioN/NotchHider/releases/tag/v\(version.description)")!
    }

    /// Last attempt, successful or not: drives `isDue`.
    public var lastChecked: Date? { defaults.object(forKey: "lastUpdateCheck") as? Date }
    /// Last time GitHub actually answered: the only time "up to date" is known to be true.
    public var lastSuccessfulCheck: Date? { defaults.object(forKey: "lastSuccessfulUpdateCheck") as? Date }

    /// True when the last check is a day old, there was none, or the clock went back before it.
    public var isDue: Bool {
        guard let lastChecked else { return true }
        let age = now().timeIntervalSince(lastChecked)
        return age < 0 || age >= Self.interval
    }

    /// The newest release seen so far, if it is newer than the running app.
    public var pendingUpdate: AppVersion? {
        guard let current, let latest = defaults.string(forKey: "latestKnownVersion").flatMap(AppVersion.init),
              current < latest else { return nil }
        return latest
    }

    /// Fetches the latest release. A failure keeps the last known version and still counts as an
    /// attempt, so automatic checks retry a day later instead of hammering the API.
    public func run() async -> UpdateResult {
        defer { defaults.set(now(), forKey: "lastUpdateCheck") }
        do {
            let data = try await fetch()
            guard let body = try? JSONDecoder().decode(LatestRelease.self, from: data) else {
                return .failed("GitHub sent an unexpected response.")
            }
            guard let latest = AppVersion(body.tag_name) else { return .failed("GitHub sent an unexpected release tag.") }
            defaults.set(latest.description, forKey: "latestKnownVersion")
            defaults.set(now(), forKey: "lastSuccessfulUpdateCheck")
            return pendingUpdate.map(UpdateResult.available) ?? .upToDate
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private struct LatestRelease: Decodable { let tag_name: String }
}
