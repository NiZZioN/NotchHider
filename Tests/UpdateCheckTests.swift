import Testing
import Foundation

private func freshDefaults() -> UserDefaults {
    let name = "notchhider.tests.\(UUID().uuidString)"
    let d = UserDefaults(suiteName: name)!
    d.removePersistentDomain(forName: name)
    return d
}

/// A GitHub "latest release" body with only the field the app reads plus some noise.
private func release(_ tag: String) -> Data {
    Data(#"{"tag_name":"\#(tag)","html_url":"https://evil.example/","draft":false,"name":"Release"}"#.utf8)
}

private let start = Date(timeIntervalSince1970: 1_800_000_000)
private let hour: TimeInterval = 3600

@Suite struct UpdateCheckTests {
    @Test func newerReleaseIsReportedAndRememberedAcrossLaunches() async {
        let d = freshDefaults()
        let check = UpdateCheck(currentVersion: "1.1.0", defaults: d, now: { start }, fetch: { release("v1.2.0") })

        let result = await check.run()

        #expect(result == .available(AppVersion("1.2.0")!))
        let relaunched = UpdateCheck(currentVersion: "1.1.0", defaults: d, now: { start }, fetch: { throw URLError(.notConnectedToInternet) })
        #expect(relaunched.pendingUpdate == AppVersion("1.2.0"))
    }

    @Test func checkIsDueOnFirstLaunchThenOncePerDay() async {
        var clock = start
        let check = UpdateCheck(currentVersion: "1.1.0", defaults: freshDefaults(), now: { clock }, fetch: { release("v1.1.0") })
        #expect(check.isDue)

        _ = await check.run()
        #expect(!check.isDue)
        clock = start + 23 * hour
        #expect(!check.isDue)
        clock = start + 24 * hour
        #expect(check.isDue)
    }

    @Test func checkIsDueWhenClockWasSetBackBeforeTheLastCheck() async {
        var clock = start
        let check = UpdateCheck(currentVersion: "1.1.0", defaults: freshDefaults(), now: { clock }, fetch: { release("v1.1.0") })
        _ = await check.run()

        clock = start - 2 * hour
        #expect(check.isDue)
    }

    static let failures: [Result<Data, URLError>] = [
        .failure(URLError(.notConnectedToInternet)),
        .success(Data(#"{"message":"API rate limit exceeded"}"#.utf8)),
        .success(Data(#"{"message":"Not Found"}"#.utf8)),
        .success(Data("<html>".utf8)),
        .success(release("v1.3.0/../../evil")),
    ]

    @Test(arguments: failures)
    func failedCheckKeepsTheKnownUpdateAndWaitsADay(_ failure: Result<Data, URLError>) async {
        var clock = start
        var response: Result<Data, URLError> = .success(release("v1.2.0"))
        let check = UpdateCheck(currentVersion: "1.1.0", defaults: freshDefaults(), now: { clock },
                                fetch: { try response.get() })
        _ = await check.run()

        clock = start + 25 * hour
        response = failure
        let result = await check.run()

        guard case .failed = result else { Issue.record("expected failure, got \(result)"); return }
        #expect(check.pendingUpdate == AppVersion("1.2.0"))
        #expect(check.lastChecked == clock)
        #expect(!check.isDue)
    }

    @Test(arguments: ["v1.1.0", "v1.1", "v1.0.9"])
    func sameOrOlderReleaseIsUpToDate(_ tag: String) async {
        let check = UpdateCheck(currentVersion: "1.1.0", defaults: freshDefaults(), now: { start }, fetch: { release(tag) })
        #expect(await check.run() == .upToDate)
        #expect(check.pendingUpdate == nil)
    }

    @Test func noticeDisappearsOnceTheUserRunsThatVersion() async {
        let d = freshDefaults()
        _ = await UpdateCheck(currentVersion: "1.1.0", defaults: d, now: { start }, fetch: { release("v1.2.0") }).run()

        let upgraded = UpdateCheck(currentVersion: "1.2.0", defaults: d, now: { start }, fetch: { release("v1.2.0") })
        #expect(upgraded.pendingUpdate == nil)
    }

    @Test func unreadableRunningVersionNeverClaimsAnUpdate() async {
        let check = UpdateCheck(currentVersion: "dev", defaults: freshDefaults(), now: { start }, fetch: { release("v9.0.0") })
        #expect(await check.run() == .upToDate)
        #expect(check.pendingUpdate == nil)
    }

    @Test func releasePageIsBuiltFromTheVersionNotFromTheResponse() async throws {
        let check = UpdateCheck(currentVersion: "1.1.0", defaults: freshDefaults(), now: { start }, fetch: { release("v1.2.0") })
        _ = await check.run()

        let version = try #require(check.pendingUpdate)
        #expect(UpdateCheck.releasePage(for: version).absoluteString
                == "https://github.com/NiZZioN/NotchHider/releases/tag/v1.2.0")
    }

    @Test func failedAttemptDoesNotCountAsAConfirmedCheck() async {
        var clock = start
        var response: Result<Data, URLError> = .success(release("v1.1.0"))
        let check = UpdateCheck(currentVersion: "1.1.0", defaults: freshDefaults(), now: { clock },
                                fetch: { try response.get() })
        _ = await check.run()

        clock = start + 25 * hour
        response = .failure(URLError(.timedOut))
        _ = await check.run()

        #expect(check.lastChecked == start + 25 * hour)
        #expect(check.lastSuccessfulCheck == start)
    }

    @Test func firstAttemptFailingLeavesNoConfirmedCheck() async {
        let check = UpdateCheck(currentVersion: "1.1.0", defaults: freshDefaults(), now: { start },
                                fetch: { throw URLError(.notConnectedToInternet) })
        _ = await check.run()
        #expect(check.lastSuccessfulCheck == nil)
    }
}
