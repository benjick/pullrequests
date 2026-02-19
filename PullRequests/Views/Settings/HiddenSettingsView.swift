import SwiftUI

struct HiddenSettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hidden Pull Requests")
                    .font(.headline)
                Text("These PRs are hidden from the popover. Click unhide to show them again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            if appState.config.hiddenPRs.isEmpty {
                VStack {
                    Spacer()
                    Text("No hidden PRs")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(appState.config.hiddenPRs.sorted(), id: \.self) { prID in
                        HStack {
                            Image(systemName: "eye.slash")
                                .foregroundStyle(.secondary)
                            Text(prID)

                            Spacer()

                            Button("Unhide") {
                                unhide(prID)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
    }

    private func unhide(_ prID: String) {
        appState.config.hiddenPRs.remove(prID)
        ConfigManager.shared.save(appState.config)
    }
}
