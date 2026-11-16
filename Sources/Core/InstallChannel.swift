import Foundation

/// How the app got onto this Mac, which decides how the user should update it.
public enum InstallChannel: Equatable {
    /// Installed by the Homebrew cask: updating by hand would leave brew's record stale.
    case homebrew
    /// get.sh, install.sh or a downloaded zip.
    case direct

    public static let homebrewUpgradeCommand = "brew upgrade --cask notchhider"

    static let caskroomPaths = ["/opt/homebrew/Caskroom/notchhider", "/usr/local/Caskroom/notchhider"]

    public static func detect(fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }) -> InstallChannel {
        caskroomPaths.contains(where: fileExists) ? .homebrew : .direct
    }
}
