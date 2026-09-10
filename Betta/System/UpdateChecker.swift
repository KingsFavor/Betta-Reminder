import AppKit
import Observation
import SwiftUI

/// Quiet "a new version is available" check for the Developer ID / Homebrew build.
///
/// Deliberately unobtrusive:
/// - Read-only outbound HTTPS to the public GitHub Releases API — App Sandbox safe.
/// - Checks at most once per 24h, and only on launch. No polling timer.
/// - A network failure is silent — never surfaced as an error to the user.
/// - The result is cached so a known update reappears across relaunches without a
///   network call, and disappears once the running version catches up.
///
/// Installed via Homebrew Cask, so we don't self-update: the banner links to the
/// release page and shows the `brew upgrade` command.
@MainActor
@Observable
final class UpdateChecker {
    static let latestReleaseAPI = URL(string: "https://api.github.com/repos/KingsFavor/Betta-Reminder/releases/latest")!
    static let brewUpdateCommand = "brew update && brew upgrade --cask betta"
    private static let throttle: TimeInterval = 60 * 60 * 24   // once per day

    let currentVersion: String =
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"

    private(set) var latestVersion: String?
    private(set) var releaseURL: URL?
    private(set) var isChecking = false

    enum CheckResult: Equatable { case idle, upToDate, available(String), failed }
    private(set) var lastResult: CheckResult = .idle

    private let defaults = UserDefaults.standard
    private enum Key {
        static let enabled = "update.autoCheckEnabled"
        static let lastCheck = "update.lastCheckAt"
        static let skipped = "update.skippedVersion"
        static let cachedVersion = "update.cachedVersion"
        static let cachedURL = "update.cachedURL"
    }

    var autoCheckEnabled: Bool {
        get { defaults.object(forKey: Key.enabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    /// The banner appears only for a real, newer, non-skipped version.
    var isBannerVisible: Bool {
        guard let latest = latestVersion else { return false }
        return defaults.string(forKey: Key.skipped) != latest
    }

    // MARK: Launch

    func checkOnLaunch() {
        restoreCache()
        guard autoCheckEnabled else { return }
        if let last = defaults.object(forKey: Key.lastCheck) as? Date,
           Date().timeIntervalSince(last) < Self.throttle {
            return
        }
        Task { await performCheck() }
    }

    // MARK: User actions

    /// "지금 확인" from Settings / menu — ignores the throttle and re-shows a skipped version.
    func checkForUpdatesInteractive() {
        guard !isChecking else { return }
        defaults.removeObject(forKey: Key.skipped)
        Task {
            await performCheck()
            presentResultAlert()
        }
    }

    private func presentResultAlert() {
        let alert = NSAlert()
        switch lastResult {
        case .available(let v):
            alert.messageText = "새 버전이 있어요 (\(v))"
            alert.informativeText = "버전 \(currentVersion) → \(v)\n\n\(Self.brewUpdateCommand)"
            alert.addButton(withTitle: "명령 복사")
            alert.addButton(withTitle: "릴리스 페이지 열기")
            alert.addButton(withTitle: "나중에")
            switch alert.runModal() {
            case .alertFirstButtonReturn:  copyUpdateCommand()
            case .alertSecondButtonReturn: openReleasePage()
            default: break
            }
            return
        case .upToDate:
            alert.messageText = "최신 버전입니다"
            alert.informativeText = "버전 \(currentVersion)"
        case .failed:
            alert.messageText = "업데이트를 확인하지 못했어요"
            alert.informativeText = "연결을 확인하고 다시 시도해 주세요."
        case .idle:
            return
        }
        alert.addButton(withTitle: "확인")
        alert.runModal()
    }

    func dismissBanner() {
        if let latest = latestVersion { defaults.set(latest, forKey: Key.skipped) }
    }

    func openReleasePage() {
        if let url = releaseURL { NSWorkspace.shared.open(url) }
    }

    func copyUpdateCommand() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(Self.brewUpdateCommand, forType: .string)
    }

    // MARK: Internal

    private func restoreCache() {
        guard let cached = defaults.string(forKey: Key.cachedVersion),
              Self.isNewer(cached, than: currentVersion) else {
            latestVersion = nil; releaseURL = nil
            return
        }
        latestVersion = cached
        releaseURL = defaults.string(forKey: Key.cachedURL).flatMap { URL(string: $0) }
        lastResult = .available(cached)
    }

    private func performCheck() async {
        isChecking = true
        defer { isChecking = false }
        defaults.set(Date(), forKey: Key.lastCheck)

        do {
            var req = URLRequest(url: Self.latestReleaseAPI, timeoutInterval: 10)
            req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            req.setValue("Betta/\(currentVersion)", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                lastResult = .failed
                return
            }
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let tag = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName

            if Self.isNewer(tag, than: currentVersion) {
                latestVersion = tag
                releaseURL = URL(string: release.htmlURL)
                lastResult = .available(tag)
                defaults.set(tag, forKey: Key.cachedVersion)
                defaults.set(release.htmlURL, forKey: Key.cachedURL)
            } else {
                latestVersion = nil
                releaseURL = nil
                lastResult = .upToDate
                defaults.removeObject(forKey: Key.cachedVersion)
                defaults.removeObject(forKey: Key.cachedURL)
            }
        } catch {
            lastResult = .failed
        }
    }

    /// Numeric dotted-version compare ("0.2.0" > "0.1.9"); missing components = 0.
    static func isNewer(_ candidate: String, than base: String) -> Bool {
        func parts(_ s: String) -> [Int] {
            s.split(separator: ".").map { Int($0.prefix(while: \.isNumber)) ?? 0 }
        }
        let a = parts(candidate), b = parts(base)
        for i in 0..<max(a.count, b.count) {
            let l = i < a.count ? a[i] : 0
            let r = i < b.count ? b[i] : 0
            if l != r { return l > r }
        }
        return false
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: String
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}
