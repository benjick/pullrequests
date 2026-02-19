import Foundation

struct PullRequest: Identifiable, Equatable {
    let id: String  // "owner/repo#number"
    let number: Int
    let title: String
    let url: String
    let isDraft: Bool
    let author: Author
    let repository: Repository
    let reviewStatus: ReviewStatus
    let ciStatus: CIStatus
    let mergeableState: MergeableState
    let updatedAt: Date
    let reviewRequestedUsers: [String]  // usernames requested for review
    let comments: [Comment]
    let reviews: [Review]

    var repoFullName: String { "\(repository.owner)/\(repository.name)" }

    struct Author: Equatable {
        let login: String
        let avatarURL: String?
    }

    struct Review: Equatable {
        let author: String
        let state: ReviewState
        let submittedAt: Date?
    }

    struct Comment: Equatable, Identifiable {
        let id: String
        let author: String
        let isBot: Bool
        let body: String
        let createdAt: Date
    }

    enum ReviewState: String, Equatable {
        case approved = "APPROVED"
        case changesRequested = "CHANGES_REQUESTED"
        case commented = "COMMENTED"
        case dismissed = "DISMISSED"
        case pending = "PENDING"
    }

    enum ReviewStatus: Equatable {
        case approved
        case changesRequested
        case pending
        case none
    }

    enum CIStatus: Equatable {
        case success
        case failure
        case pending
        case none
    }

    enum MergeableState: String, Equatable {
        case mergeable = "MERGEABLE"
        case conflicting = "CONFLICTING"
        case unknown = "UNKNOWN"
    }
}
