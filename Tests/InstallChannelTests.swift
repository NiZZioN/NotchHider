import Testing

@Suite struct InstallChannelTests {
    @Test(arguments: ["/opt/homebrew/Caskroom/notchhider", "/usr/local/Caskroom/notchhider"])
    func caskroomFolderMeansHomebrew(_ path: String) {
        #expect(InstallChannel.detect(fileExists: { $0 == path }) == .homebrew)
    }

    @Test func noCaskroomFolderMeansDirectInstall() {
        #expect(InstallChannel.detect(fileExists: { _ in false }) == .direct)
    }

    @Test func homebrewUsersAreToldToUpgradeThroughBrew() {
        #expect(InstallChannel.homebrewUpgradeCommand == "brew upgrade --cask notchhider")
    }
}
