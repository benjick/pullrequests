import Foundation

@MainActor
class GitHubService {
    private let endpoint = URL(string: "https://api.github.com/graphql")!

    // MARK: - Token Validation

    func validateToken(_ token: String) async throws -> String {
        let query = "query { viewer { login } }"
        let result = try await executeQuery(query, token: token)

        guard let data = result["data"] as? [String: Any],
              let viewer = data["viewer"] as? [String: Any],
              let login = viewer["login"] as? String else {
            throw GitHubError.invalidResponse
        }

        return login
    }

    // MARK: - Repository Validation

    func validateRepository(_ repo: Repository, token: String) async throws -> Bool {
        let query = """
        query { repository(owner: "\(repo.owner)", name: "\(repo.name)") { name } }
        """
        let result = try await executeQuery(query, token: token)

        guard let data = result["data"] as? [String: Any] else {
            if let errors = result["errors"] as? [[String: Any]] {
                let message = errors.first?["message"] as? String ?? "Unknown error"
                throw GitHubError.apiError(message)
            }
            throw GitHubError.invalidResponse
        }

        return data["repository"] != nil
    }

    // MARK: - Fetch Pull Requests

    func fetchPullRequests(repos: [Repository], username: String, token: String) async throws -> [PullRequest] {
        guard !repos.isEmpty else { return [] }

        let query = buildQuery(repos: repos)
        let result = try await executeQuery(query, token: token)

        guard let data = result["data"] as? [String: Any] else {
            if let errors = result["errors"] as? [[String: Any]] {
                let message = errors.first?["message"] as? String ?? "Unknown error"
                throw GitHubError.apiError(message)
            }
            throw GitHubError.invalidResponse
        }

        var pullRequests: [PullRequest] = []
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        func parseDate(_ string: String) -> Date {
            dateFormatter.date(from: string) ?? fallbackFormatter.date(from: string) ?? Date()
        }

        for (index, repo) in repos.enumerated() {
            let key = "repo\(index)"
            guard let repoData = data[key] as? [String: Any],
                  let prsData = repoData["pullRequests"] as? [String: Any],
                  let nodes = prsData["nodes"] as? [[String: Any]] else {
                continue
            }

            for node in nodes {
                guard let number = node["number"] as? Int,
                      let title = node["title"] as? String,
                      let url = node["url"] as? String,
                      let updatedAtStr = node["updatedAt"] as? String else {
                    continue
                }

                let isDraft = node["isDraft"] as? Bool ?? false
                let mergeableStr = node["mergeable"] as? String ?? "UNKNOWN"

                // Parse author
                let authorData = node["author"] as? [String: Any]
                let author = PullRequest.Author(
                    login: authorData?["login"] as? String ?? "unknown",
                    avatarURL: authorData?["avatarUrl"] as? String
                )

                // Parse review requests
                let reviewRequestsData = node["reviewRequests"] as? [String: Any]
                let reviewRequestNodes = reviewRequestsData?["nodes"] as? [[String: Any]] ?? []
                let reviewRequestedUsers = reviewRequestNodes.compactMap { reqNode -> String? in
                    let reviewer = reqNode["requestedReviewer"] as? [String: Any]
                    return reviewer?["login"] as? String
                }

                // Parse reviews
                let reviewsData = node["reviews"] as? [String: Any]
                let reviewNodes = reviewsData?["nodes"] as? [[String: Any]] ?? []
                let reviews = reviewNodes.compactMap { reviewNode -> PullRequest.Review? in
                    let reviewAuthor = reviewNode["author"] as? [String: Any]
                    guard let login = reviewAuthor?["login"] as? String,
                          let stateStr = reviewNode["state"] as? String,
                          let state = PullRequest.ReviewState(rawValue: stateStr) else {
                        return nil
                    }
                    let submittedAt = (reviewNode["submittedAt"] as? String).map(parseDate)
                    return PullRequest.Review(author: login, state: state, submittedAt: submittedAt)
                }

                // Parse comments
                let commentsData = node["comments"] as? [String: Any]
                let commentNodes = commentsData?["nodes"] as? [[String: Any]] ?? []
                let comments = commentNodes.compactMap { commentNode -> PullRequest.Comment? in
                    let commentAuthor = commentNode["author"] as? [String: Any]
                    guard let login = commentAuthor?["login"] as? String,
                          let body = commentNode["body"] as? String,
                          let id = commentNode["id"] as? String,
                          let createdAtStr = commentNode["createdAt"] as? String else {
                        return nil
                    }
                    let typeName = commentAuthor?["__typename"] as? String ?? "User"
                    let isBot = typeName == "Bot"
                    return PullRequest.Comment(id: id, author: login, isBot: isBot, body: body, createdAt: parseDate(createdAtStr))
                }

                // Derive CI status
                let ciStatus = deriveCIStatus(from: node)

                // Derive review status
                let reviewStatus = deriveReviewStatus(from: reviews)

                let pr = PullRequest(
                    id: "\(repo.owner)/\(repo.name)#\(number)",
                    number: number,
                    title: title,
                    url: url,
                    isDraft: isDraft,
                    author: author,
                    repository: repo,
                    reviewStatus: reviewStatus,
                    ciStatus: ciStatus,
                    mergeableState: PullRequest.MergeableState(rawValue: mergeableStr) ?? .unknown,
                    updatedAt: parseDate(updatedAtStr),
                    reviewRequestedUsers: reviewRequestedUsers,
                    comments: comments,
                    reviews: reviews
                )

                pullRequests.append(pr)
            }
        }

        return pullRequests
    }

    // MARK: - Private Helpers

    private func buildQuery(repos: [Repository]) -> String {
        let fragment = """
        pullRequests(first: 30, states: OPEN, orderBy: {field: UPDATED_AT, direction: DESC}) {
            nodes {
                number
                title
                isDraft
                url
                mergeable
                updatedAt
                author {
                    login
                    avatarUrl
                }
                reviewRequests(first: 20) {
                    nodes {
                        requestedReviewer {
                            ... on User { login }
                        }
                    }
                }
                reviews(last: 10) {
                    nodes {
                        author { login }
                        state
                        submittedAt
                    }
                }
                commits(last: 1) {
                    nodes {
                        commit {
                            statusCheckRollup {
                                state
                            }
                        }
                    }
                }
                comments(last: 5) {
                    nodes {
                        id
                        author { login __typename }
                        body
                        createdAt
                    }
                }
            }
        }
        """

        var queryParts: [String] = []
        for (index, repo) in repos.enumerated() {
            queryParts.append("""
            repo\(index): repository(owner: "\(repo.owner)", name: "\(repo.name)") {
                \(fragment)
            }
            """)
        }

        return "query {\n\(queryParts.joined(separator: "\n"))\n}"
    }

    private func executeQuery(_ query: String, token: String) async throws -> [String: Any] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw GitHubError.unauthorized
            }
            throw GitHubError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GitHubError.invalidResponse
        }

        return json
    }

    private func deriveCIStatus(from node: [String: Any]) -> PullRequest.CIStatus {
        guard let commits = node["commits"] as? [String: Any],
              let commitNodes = commits["nodes"] as? [[String: Any]],
              let lastCommit = commitNodes.last,
              let commit = lastCommit["commit"] as? [String: Any],
              let rollup = commit["statusCheckRollup"] as? [String: Any],
              let state = rollup["state"] as? String else {
            return .none
        }

        switch state {
        case "SUCCESS": return .success
        case "FAILURE", "ERROR": return .failure
        case "PENDING", "EXPECTED": return .pending
        default: return .none
        }
    }

    private func deriveReviewStatus(from reviews: [PullRequest.Review]) -> PullRequest.ReviewStatus {
        guard !reviews.isEmpty else { return .none }

        // Get the last non-dismissed review per reviewer
        var latestByReviewer: [String: PullRequest.ReviewState] = [:]
        for review in reviews {
            if review.state == .dismissed { continue }
            if review.state == .commented { continue }
            latestByReviewer[review.author] = review.state
        }

        guard !latestByReviewer.isEmpty else { return .pending }

        if latestByReviewer.values.contains(.changesRequested) {
            return .changesRequested
        }
        if latestByReviewer.values.contains(.approved) {
            return .approved
        }
        return .pending
    }
}

enum GitHubError: LocalizedError {
    case invalidResponse
    case unauthorized
    case httpError(Int)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from GitHub"
        case .unauthorized: return "Invalid or expired token"
        case .httpError(let code): return "HTTP error: \(code)"
        case .apiError(let message): return message
        }
    }
}
