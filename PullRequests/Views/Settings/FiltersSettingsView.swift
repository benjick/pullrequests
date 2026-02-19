import SwiftUI

struct FiltersSettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bot Accounts")
                    .font(.headline)
                Text("Bots are auto-discovered from PR comments. Ignored bots won't trigger notifications.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            if appState.config.discoveredBots.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "robot")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("No bots discovered yet")
                        .foregroundStyle(.secondary)
                    Text("Bots will appear here automatically as they comment on your PRs.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(appState.config.discoveredBots.sorted(), id: \.self) { bot in
                        HStack {
                            Image(systemName: "robot")
                                .foregroundStyle(.secondary)
                            Text(bot)

                            Spacer()

                            Picker("", selection: botBinding(for: bot)) {
                                Text("Ignore").tag(false)
                                Text("Allow").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 140)
                        }
                    }
                }
            }
        }
    }

    private func botBinding(for bot: String) -> Binding<Bool> {
        Binding(
            get: { appState.config.allowedBots.contains(bot) },
            set: { allowed in
                if allowed {
                    appState.config.allowedBots.insert(bot)
                } else {
                    appState.config.allowedBots.remove(bot)
                }
                ConfigManager.shared.save(appState.config)
            }
        )
    }
}
