import SwiftUI

struct PRRowView: View {
    let pr: PullRequest
    @Bindable var appState: AppState
    var onDismiss: (() -> Void)?

    var body: some View {
        Button(action: openInBrowser) {
            HStack(alignment: .top, spacing: 10) {
                // Avatar
                AsyncImage(url: URL(string: pr.author.avatarURL ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundStyle(.secondary)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    // Title
                    Text(pr.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(pr.isDraft ? .secondary : .primary)

                    // Repo + number + time
                    HStack(spacing: 6) {
                        Text(pr.repoFullName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("#\(pr.number)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Spacer()

                        RelativeTimeText(date: pr.updatedAt)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    // Status badges
                    HStack(spacing: 8) {
                        if pr.isDraft {
                            StatusBadge(icon: "doc.text", color: .secondary, label: "Draft")
                        }

                        reviewStatusBadge

                        ciStatusBadge

                        if pr.mergeableState == .conflicting {
                            StatusBadge(icon: "exclamationmark.triangle.fill", color: .orange, label: "Conflicts")
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.clear)
        .contextMenu {
            Button("Open in GitHub") { openInBrowser() }
            Button("Copy URL") { copyURL() }
            Divider()
            if appState.config.mutedPRs.contains(pr.id) {
                Button("Unmute") { toggleMute() }
            } else {
                Button("Mute") { toggleMute() }
            }
            Button("Hide") { hidePR() }
        }
    }

    @ViewBuilder
    private var reviewStatusBadge: some View {
        switch pr.reviewStatus {
        case .approved:
            StatusBadge(icon: "checkmark.circle.fill", color: .green, label: "Approved")
        case .changesRequested:
            StatusBadge(icon: "xmark.circle.fill", color: .red, label: "Changes requested")
        case .pending:
            StatusBadge(icon: "clock.fill", color: .yellow, label: "Review pending")
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var ciStatusBadge: some View {
        switch pr.ciStatus {
        case .success:
            StatusBadge(icon: "checkmark.diamond.fill", color: .green, label: "CI passed")
        case .failure:
            StatusBadge(icon: "xmark.diamond.fill", color: .red, label: "CI failed")
        case .pending:
            StatusBadge(icon: "clock.badge.checkmark", color: .yellow, label: "CI running")
        case .none:
            EmptyView()
        }
    }

    // MARK: - Actions

    private func openInBrowser() {
        if let url = URL(string: pr.url) {
            onDismiss?()
            NSWorkspace.shared.open(url)
        }
    }

    private func copyURL() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(pr.url, forType: .string)
    }

    private func toggleMute() {
        if appState.config.mutedPRs.contains(pr.id) {
            appState.config.mutedPRs.remove(pr.id)
        } else {
            appState.config.mutedPRs.insert(pr.id)
        }
        ConfigManager.shared.save(appState.config)
    }

    private func hidePR() {
        appState.config.hiddenPRs.insert(pr.id)
        ConfigManager.shared.save(appState.config)
    }
}
