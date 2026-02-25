import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private let menuBarController = MenuBarController()
    private let settingsWindowController = SettingsWindowController()
    private let configManager = ConfigManager.shared
    private let keychainHelper = KeychainHelper()
    private var gitHubService: GitHubService?
    private var pollingService: PollingService?
    private var notificationService: NotificationService?
    private var previousPRs: [PullRequest] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadConfig()
        setupMenuBar()
        setupSettingsWindow()
        setupConfigChangeListener()
        setupNotificationService()
        startPollingIfConfigured()
    }

    func applicationWillTerminate(_ notification: Notification) {
        pollingService?.stop()
    }

    // MARK: - Setup

    private func loadConfig() {
        appState.config = configManager.load()
        if let token = keychainHelper.load() {
            appState.token = token
        }
    }

    private func setupMenuBar() {
        menuBarController.setup(appState: appState)

        menuBarController.onOpenSettings = { [weak self] in
            self?.settingsWindowController.showWindow()
        }

        menuBarController.onRefresh = { [weak self] in
            Task { @MainActor in
                await self?.pollingService?.pollNow()
            }
        }

        menuBarController.onQuit = {
            NSApplication.shared.terminate(nil)
        }
    }

    private func setupSettingsWindow() {
        settingsWindowController.setup(appState: appState)
    }

    private func setupNotificationService() {
        notificationService = NotificationService()
        notificationService?.requestPermission()
        appState.notificationService = notificationService
    }

    private func setupConfigChangeListener() {
        NotificationCenter.default.addObserver(
            forName: .configChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.menuBarController.updateBadge()
                self.restartPolling()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .tokenChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.restartPolling()
            }
        }
    }

    private func startPollingIfConfigured() {
        guard !appState.token.isEmpty, !appState.config.repositories.isEmpty else { return }
        startPolling()
    }

    private func startPolling() {
        pollingService?.stop()

        let service = GitHubService()
        gitHubService = service

        let polling = PollingService(
            gitHubService: service,
            appState: appState
        )

        polling.onFetchCompleted = { [weak self] oldPRs, newPRs in
            guard let self = self else { return }
            self.handlePRUpdate(oldPRs: oldPRs, newPRs: newPRs)
        }

        pollingService = polling
        polling.start()
    }

    private func restartPolling() {
        pollingService?.stop()
        if !appState.token.isEmpty, !appState.config.repositories.isEmpty {
            startPolling()
        }
    }

    private func discoverBots(in prs: [PullRequest]) {
        var foundNew = false
        for pr in prs {
            for comment in pr.comments where comment.isBot {
                if !appState.config.discoveredBots.contains(comment.author) {
                    appState.config.discoveredBots.insert(comment.author)
                    foundNew = true
                }
            }
        }
        if foundNew {
            configManager.save(appState.config)
        }
    }

    private func handlePRUpdate(oldPRs: [PullRequest], newPRs: [PullRequest]) {
        menuBarController.updateBadge()
        discoverBots(in: newPRs)

        guard !oldPRs.isEmpty else { return }

        let changes = PRDiffEngine.computeChanges(
            old: oldPRs,
            new: newPRs,
            username: appState.authenticatedUsername,
            allowedBots: appState.config.allowedBots
        )

        let config = appState.config
        let mutedPRs = appState.config.mutedPRs

        for change in changes {
            if mutedPRs.contains(change.prID) { continue }

            switch change.kind {
            case .newComment:
                if config.notifyOnComments {
                    notificationService?.send(change: change)
                }
            case .reviewStatusChanged:
                if config.notifyOnReviewStatus {
                    notificationService?.send(change: change)
                }
            case .ciFinished:
                if config.notifyOnCI && change.prAuthor == appState.authenticatedUsername {
                    notificationService?.send(change: change)
                }
            case .reviewRequested:
                if config.notifyOnReviewRequested {
                    notificationService?.send(change: change)
                }
            }
        }
    }
}
