import Foundation
import os

private let log = Logger(subsystem: "com.pullrequests.app", category: "updates")

/// Checks GitHub for a newer release and exposes it on `AppState.availableUpdate`.
/// Updating itself is left to Homebrew.
@MainActor
final class UpdateChecker {
    static let brewCommand = "brew update && brew upgrade --cask pullrequests"

    static let releasesPageURL = URL(string: "https://github.com/benjick/pullrequests/releases")!
    private static let releasesURL = URL(string: "https://api.github.com/repos/benjick/pullrequests/releases?per_page=30")!
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
        var request = URLRequest(url: Self.releasesURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let releases = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                log.error("Unexpected response from GitHub releases")
                return
            }
            // Every published release newer than the running one, newest first,
            // so someone who skipped versions sees everything they missed.
            let newer: [(version: [Int], notes: ReleaseNotes)] = releases.compactMap { release in
                guard release["draft"] as? Bool != true, release["prerelease"] as? Bool != true,
                      let tag = release["tag_name"] as? String,
                      let version = Self.parse(tag),
                      Self.compare(version, current) > 0 else { return nil }
                let name = version.map(String.init).joined(separator: ".")
                return (version, ReleaseNotes(version: name, body: release["body"] as? String ?? ""))
            }
            .sorted { Self.compare($0.version, $1.version) > 0 }

            appState?.availableUpdate = newer.first?.notes.version
            appState?.updateNotes = newer.map(\.notes)
            log.info("Releases newer than this one: \(newer.count)")
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

/// One release's notes, split into lines for display. Markdown bullets
/// ("- foo", with indented continuation lines) become one entry each.
struct ReleaseNotes: Identifiable {
    let version: String
    let lines: [Line]
    var id: String { version }

    struct Line: Hashable {
        var text: String
        var isBullet: Bool
    }

    init(version: String, body: String) {
        self.version = version
        var lines: [Line] = []
        for raw in body.components(separatedBy: .newlines) {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                lines.append(Line(text: String(trimmed.dropFirst(2)), isBullet: true))
            } else if raw.hasPrefix(" "), !lines.isEmpty {
                lines[lines.count - 1].text += " " + trimmed
            } else {
                lines.append(Line(text: trimmed, isBullet: false))
            }
        }
        self.lines = lines
    }
}
