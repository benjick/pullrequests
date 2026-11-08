import Foundation
import os

private let log = Logger(subsystem: "com.pullrequests.app", category: "updates")

/// Checks GitHub for a newer release and exposes it on `AppState.availableUpdate`.
/// Updating itself is left to Homebrew.
@MainActor
final class UpdateChecker {
    static let brewCommand = "brew update && brew upgrade --cask pullrequests"

    private static let latestReleaseURL = URL(string: "https://api.github.com/repos/benjick/pullrequests/releases/latest")!
    private static let interval: TimeInterval = 6 * 60 * 60

    private weak var appState: AppState?
    private var timer: Timer?

    init(appState: AppState) {
        self.appState = appState
    }

    func start() {
        // Local builds report "dev" and have nothing to compare against.
        guard let current = Self.currentVersion else {
            log.info("Skipping update checks for a development build")
            return
        }
        Task { await check(current: current) }
        timer = Timer.scheduledTimer(withTimeInterval: Self.interval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.check(current: current) }
        }
    }

    private func check(current: [Int]) async {
        var request = URLRequest(url: Self.latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String,
                  let latest = Self.parse(tag) else {
                log.error("Unexpected response from GitHub releases")
                return
            }
            let isNewer = Self.compare(latest, current) > 0
            appState?.availableUpdate = isNewer ? latest.map(String.init).joined(separator: ".") : nil
            log.info("Latest release \(tag, privacy: .public), update available: \(isNewer)")
        } catch {
            // Offline or rate limited; try again at the next interval.
            log.error("Update check failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static var currentVersion: [Int]? {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String).flatMap(parse)
    }

    /// "v1.2.3" or "1.2.3" -> [1, 2, 3]; nil for anything else (e.g. "dev").
    private static func parse(_ version: String) -> [Int]? {
        let trimmed = version.hasPrefix("v") ? String(version.dropFirst()) : version
        let parts = trimmed.split(separator: ".").map { Int($0) }
        guard !parts.isEmpty, parts.allSatisfy({ $0 != nil }) else { return nil }
        return parts.compactMap { $0 }
    }

    /// Compares version components, treating missing ones as 0 (1.2 == 1.2.0).
    private static func compare(_ a: [Int], _ b: [Int]) -> Int {
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x < y ? -1 : 1 }
        }
        return 0
    }
}
