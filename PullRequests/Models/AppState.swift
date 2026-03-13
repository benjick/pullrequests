import Foundation

@Observable
@MainActor
class AppState {
    var config: AppConfig
    var token: String = ""
    var authenticatedUsername: String = ""
    var myPRs: [PullRequest] = []
    var needsReviewPRs: [PullRequest] = []
    var isLoading: Bool = false
    var lastError: String?
    var lastFetchTime: Date?
    var notificationService: NotificationService?

    var needsReviewCount: Int { needsReviewPRs.filter { $0.reviewStatus != .approved }.count }
    var approvedPRCount: Int { myPRs.filter { $0.reviewStatus == .approved }.count }

    // Unified view sections
    var readyToMerge: [PullRequest] {
        myPRs.filter { $0.reviewStatus == .approved }
    }
    var waitingForReview: [PullRequest] {
        myPRs.filter { $0.reviewStatus != .approved }
    }
    var allSectionsEmpty: Bool {
        readyToMerge.isEmpty && needsReviewPRs.isEmpty && waitingForReview.isEmpty
    }

    var isConfigured: Bool {
        !token.isEmpty && !config.repositories.isEmpty
    }

    init(config: AppConfig = .default) {
        self.config = config
    }
}
