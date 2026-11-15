import Testing

@Suite struct AppVersionTests {
    @Test func releaseTagIsNewerThanRunningVersion() throws {
        let running = try #require(AppVersion("1.1.0"))
        let tag = try #require(AppVersion("v1.2.0"))
        #expect(running < tag)
        #expect(tag.description == "1.2.0")
    }

    @Test func missingTrailingZeroIsTheSameVersion() throws {
        let short = try #require(AppVersion("1.1"))
        let long = try #require(AppVersion("1.1.0"))
        #expect(short == long)
        #expect(!(short < long) && !(long < short))
    }

    @Test func componentsCompareAsNumbersNotText() throws {
        #expect(try #require(AppVersion("1.9.0")) < #require(AppVersion("1.10.0")))
    }

    @Test(arguments: ["", "v", "1..2", ".1.2", "1.2.", "1.2.0-beta", "1.2.0/../x", "1.2.0?a=b",
                      "+1.2", "1.-2", "１.２", "1.2.3.4.5", "99999999999999999999.0", "V1.2", " 1.2"])
    func anythingButPlainDottedNumbersIsRejected(_ tag: String) {
        #expect(AppVersion(tag) == nil)
    }
}
