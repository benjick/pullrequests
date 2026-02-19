import Foundation

struct PRChange {
    let prID: String
    let prTitle: String
    let prURL: String
    let repoName: String
    let kind: Kind

    enum Kind {
        case newComment(author: String, body: String)
        case reviewStatusChanged(from: PullRequest.ReviewStatus, to: PullRequest.ReviewStatus)
        case ciFinished(status: PullRequest.CIStatus)
        case reviewRequested
    }
}

enum PRDiffEngine {
    static func computeChanges(
        old: [PullRequest],
        new: [PullRequest],
        username: String,
        allowedBots: Set<String>
    ) -> [PRChange] {
        let oldByID = Dictionary(old.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
        var changes: [PRChange] = []

        for newPR in new {
            guard let oldPR = oldByID[newPR.id] else {
                // New PR where user is requested reviewer
                if newPR.reviewRequestedUsers.contains(username) {
                    changes.append(PRChange(
                        prID: newPR.id,
                        prTitle: newPR.title,
                        prURL: newPR.url,
                        repoName: newPR.repoFullName,
                        kind: .reviewRequested
                    ))
                }
                continue
            }

            // Check for new comments
            let oldCommentIDs = Set(oldPR.comments.map(\.id))
            let newComments = newPR.comments.filter { !oldCommentIDs.contains($0.id) }
            for comment in newComments {
                // Skip bot comments unless explicitly allowed
                if comment.isBot && !allowedBots.contains(comment.author) { continue }
                // Skip own comments
                if comment.author == username { continue }

                changes.append(PRChange(
                    prID: newPR.id,
                    prTitle: newPR.title,
                    prURL: newPR.url,
                    repoName: newPR.repoFullName,
                    kind: .newComment(author: comment.author, body: comment.body)
                ))
            }

            // Check review status change
            if oldPR.reviewStatus != newPR.reviewStatus && newPR.reviewStatus != .none {
                changes.append(PRChange(
                    prID: newPR.id,
                    prTitle: newPR.title,
                    prURL: newPR.url,
                    repoName: newPR.repoFullName,
                    kind: .reviewStatusChanged(from: oldPR.reviewStatus, to: newPR.reviewStatus)
                ))
            }

            // Check CI status change
            if oldPR.ciStatus != newPR.ciStatus &&
               (newPR.ciStatus == .success || newPR.ciStatus == .failure) &&
               oldPR.ciStatus == .pending {
                changes.append(PRChange(
                    prID: newPR.id,
                    prTitle: newPR.title,
                    prURL: newPR.url,
                    repoName: newPR.repoFullName,
                    kind: .ciFinished(status: newPR.ciStatus)
                ))
            }

            // Check if newly requested for review
            if !oldPR.reviewRequestedUsers.contains(username) &&
               newPR.reviewRequestedUsers.contains(username) {
                changes.append(PRChange(
                    prID: newPR.id,
                    prTitle: newPR.title,
                    prURL: newPR.url,
                    repoName: newPR.repoFullName,
                    kind: .reviewRequested
                ))
            }
        }

        return changes
    }
}
