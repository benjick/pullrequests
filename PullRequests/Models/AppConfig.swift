import Foundation

struct AppConfig: Codable, Equatable {
    var repositories: [Repository] = []
    var pollInterval: TimeInterval = 30

    // Notification toggles
    var notifyOnComments: Bool = true
    var notifyOnReviewStatus: Bool = true
    var notifyOnCI: Bool = true
    var notifyOnReviewRequested: Bool = true

    // Bots — auto-discovered via GraphQL __typename, default ignored
    var discoveredBots: Set<String> = []
    var allowedBots: Set<String> = []

    // Hidden & muted PRs (stored as PR IDs: "owner/repo#number")
    var hiddenPRs: Set<String> = []
    var mutedPRs: Set<String> = []

    static let `default` = AppConfig()
}
