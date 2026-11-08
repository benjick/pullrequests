import SwiftUI

struct PopoverContentView: View {
    @Bindable var appState: AppState
    let onOpenSettings: () -> Void
    let onRefresh: () -> Void
    let onQuit: () -> Void
    var onDismiss: (() -> Void)?

    @State private var showUpdateInstructions = false
    @State private var copiedCommand = false

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
                    let sections: [(String, String, Color, [PullRequest])] = [
                        ("Ready to Merge", "checkmark.circle.fill", .green, appState.readyToMerge),
                        ("Needs Your Review", "eye.fill", .orange, appState.needsReviewPRs),
                        ("Waiting for Review", "clock.fill", .secondary, appState.waitingForReview),
                    ]
                    let nonEmpty = sections.filter { !$0.3.isEmpty }
                    LazyVStack(spacing: 0) {
                        ForEach(Array(nonEmpty.enumerated()), id: \.element.0) { index, section in
                            if index > 0 {
                                Divider()
                                    .padding(.top, 8)
                            }
                            sectionView(
                                title: section.0,
                                icon: section.1,
                                iconColor: section.2,
                                prs: section.3
                            )
                        }
                    }
                    .padding(.bottom, 4)
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
        VStack(spacing: 0) {
            if showUpdateInstructions, let version = appState.availableUpdate {
                updateInstructionsView(version: version)
                Divider()
            }
            footerBar
        }
    }

    private func updateInstructionsView(version: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !appState.updateNotes.isEmpty {
                releaseNotesView
            }

            Text("Update to \(version) with Homebrew:")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text(UpdateChecker.brewCommand)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))

                Button(copiedCommand ? "Copied" : "Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(UpdateChecker.brewCommand, forType: .string)
                    copiedCommand = true
                }
                .controlSize(.small)
            }

            Link("All release notes ↗", destination: UpdateChecker.releasesPageURL)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    /// "What's new" for every release newer than the running one. Scrolls when
    /// several versions were skipped.
    private var releaseNotesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(appState.updateNotes) { release in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What's new in \(release.version)")
                            .font(.caption.weight(.semibold))
                        ForEach(release.lines, id: \.self) { line in
                            HStack(alignment: .firstTextBaseline, spacing: 5) {
                                if line.isBullet {
                                    Text("•").foregroundStyle(.secondary)
                                }
                                Text(Self.inlineMarkdown(line.text))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 160)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Renders `code`, **bold** and links; falls back to plain text.
    private static func inlineMarkdown(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }

    private var footerBar: some View {
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

            if appState.availableUpdate != nil {
                Button {
                    showUpdateInstructions.toggle()
                    copiedCommand = false
                } label: {
                    Text("Update available")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.15), in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("A newer version of PullRequests is available")
                .padding(.trailing, 6)
            }

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
