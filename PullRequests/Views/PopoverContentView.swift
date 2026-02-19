import SwiftUI

struct PopoverContentView: View {
    @Bindable var appState: AppState
    let onOpenSettings: () -> Void
    let onRefresh: () -> Void
    let onQuit: () -> Void
    var onDismiss: (() -> Void)?

    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            if !appState.isConfigured {
                setupPromptView
            } else {
                headerView
                Divider()
                contentView
                Divider()
                footerView
            }
        }
        .frame(width: 380, height: 500)
    }

    // MARK: - Setup Prompt

    private var setupPromptView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "arrow.triangle.pull")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("PullRequests")
                .font(.title2.bold())

            Text("Configure your GitHub token and repositories to get started.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Open Settings") {
                onOpenSettings()
            }
            .buttonStyle(.borderedProminent)

            Spacer()

            footerView
        }
    }

    // MARK: - Header

    private var headerView: some View {
        Picker("", selection: $selectedTab) {
            Text("My PRs (\(appState.myPRs.count))").tag(0)
            Text("Needs Review (\(appState.needsReviewPRs.count))").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Content

    private var contentView: some View {
        Group {
            let prs = selectedTab == 0 ? appState.myPRs : appState.needsReviewPRs

            if appState.isLoading && prs.isEmpty {
                loadingView
            } else if prs.isEmpty {
                emptyView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(prs) { pr in
                            PRRowView(pr: pr, appState: appState, onDismiss: onDismiss)
                            Divider().padding(.leading, 48)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
            Text("Fetching pull requests...")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: selectedTab == 0 ? "checkmark.circle" : "eyes")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(selectedTab == 0 ? "No open PRs" : "No reviews needed")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            if let time = appState.lastFetchTime {
                RelativeTimeText(date: time, prefix: "Updated")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if let error = appState.lastError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                    .help(error)
            }

            Spacer()

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Refresh")
            .disabled(appState.isLoading)

            Button(action: onOpenSettings) {
                Image(systemName: "gear")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Settings")

            Button(action: onQuit) {
                Image(systemName: "power")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Quit")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
