import Foundation

@MainActor
class PollingService {
    private let gitHubService: GitHubService
    private weak var appState: AppState?
    private var timer: Timer?
    private var previousPRs: [PullRequest] = []

    var onFetchCompleted: ((_ oldPRs: [PullRequest], _ newPRs: [PullRequest]) -> Void)?
    var onError: ((Error) -> Void)?

    init(gitHubService: GitHubService, appState: AppState) {
        self.gitHubService = gitHubService
        self.appState = appState
    }

    func start() {
        // Validate token first, then start polling
        Task {
            await validateAndFetch()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func pollNow() async {
        await fetchPRs()
    }

    private func validateAndFetch() async {
        guard let appState = appState else { return }
        let token = appState.token

        do {
            let username = try await gitHubService.validateToken(token)
            appState.authenticatedUsername = username
            await fetchPRs()
        } catch {
            appState.lastError = error.localizedDescription
            onError?(error)
        }
    }

    private func fetchPRs() async {
        guard let appState = appState else { return }
        let token = appState.token
        let repos = appState.config.repositories

        guard !token.isEmpty, !repos.isEmpty else { return }

        appState.isLoading = true
        appState.lastError = nil

        do {
            let allPRs = try await gitHubService.fetchPullRequests(
                repos: repos,
                username: appState.authenticatedUsername,
                token: token
            )

            let oldPRs = previousPRs
            previousPRs = allPRs

            // Filter hidden PRs
            let visiblePRs = allPRs.filter { !appState.config.hiddenPRs.contains($0.id) }

            // Categorize
            let username = appState.authenticatedUsername
            appState.myPRs = visiblePRs
                .filter { $0.author.login == username }
                .sorted { $0.updatedAt > $1.updatedAt }

            appState.needsReviewPRs = visiblePRs
                .filter { $0.reviewRequestedUsers.contains(username) && $0.author.login != username }
                .sorted { $0.updatedAt > $1.updatedAt }

            appState.lastFetchTime = Date()
            appState.isLoading = false

            onFetchCompleted?(oldPRs, allPRs)
        } catch {
            appState.isLoading = false
            appState.lastError = error.localizedDescription
            onError?(error)
        }

        scheduleNextPoll()
    }

    private func scheduleNextPoll() {
        guard let appState = appState else { return }
        let interval = adaptiveInterval(
            configured: appState.config.pollInterval,
            repoCount: appState.config.repositories.count
        )

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchPRs()
            }
        }
    }

    private func adaptiveInterval(configured: TimeInterval, repoCount: Int) -> TimeInterval {
        guard repoCount > 0 else { return configured }
        // Budget: 2500 GraphQL points/hour, each repo costs ~2 points per poll
        let costPerPoll = Double(repoCount * 2)
        let minInterval = 3600.0 / (2500.0 / costPerPoll)
        return max(configured, minInterval)
    }
}
