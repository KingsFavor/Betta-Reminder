import Foundation

/// Small facts about the running build.
enum BuildInfo {
    /// Marketing version baked into the copy running right now.
    static let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"

    /// Debug (Xcode) builds. Used to disable the self-relauncher, which would
    /// otherwise loop forever as Xcode rebuilds the bundle. Release (Homebrew) = false.
    static var isDevelopment: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
