import SwiftUI

struct PopoverContentView: View {
    @Bindable var appState: AppState
    let onOpenSettings: () -> Void
    let onRefresh: () -> Void
    let onQuit: () -> Void
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if !appState.isConfigured {
                setupPromptView
            } else {
                contentView
                Divider()
                footerView
            }
        }
        .frame(width: 380)
        .frame(maxHeight: 500)
        .fixedSize(horizontal: false, vertical: true)
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

    // MARK: - Content

    private var contentView: some View {
        Group {
            if appState.isLoading && appState.allSectionsEmpty {
                loadingView
            } else if appState.allSectionsEmpty {
                emptyView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        sectionView(
                            title: "Ready to Merge",
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            prs: appState.readyToMerge
                        )
                        sectionView(
                            title: "Needs Your Review",
                            icon: "eye.fill",
                            iconColor: .orange,
                            prs: appState.needsReviewPRs
                        )
                        sectionView(
                            title: "Waiting for Review",
                            icon: "clock.fill",
                            iconColor: .secondary,
                            prs: appState.waitingForReview
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionView(title: String, icon: String, iconColor: Color, prs: [PullRequest]) -> some View {
        Group {
            if !prs.isEmpty {
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(iconColor)
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("\(prs.count)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                    ForEach(Array(prs.enumerated()), id: \.element.id) { index, pr in
                        PRRowView(pr: pr, appState: appState, onDismiss: onDismiss)
                        if index < prs.count - 1 {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Fetching pull requests...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No open pull requests")
                .font(.callout)
                .foregroundStyle(.secondary)

            Button(action: onRefresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(appState.isLoading)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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
