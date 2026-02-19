import SwiftUI

struct NotificationsSettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Section("Notification Types") {
                Toggle("Comments on your PRs", isOn: binding(\.notifyOnComments))
                Toggle("Review status changes", isOn: binding(\.notifyOnReviewStatus))
                Toggle("CI/CD completion", isOn: binding(\.notifyOnCI))
                Toggle("Review requests", isOn: binding(\.notifyOnReviewRequested))
            }

            Section {
                Button("Send Test Notification") {
                    appState.notificationService?.sendTest()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func binding(_ keyPath: WritableKeyPath<AppConfig, Bool>) -> Binding<Bool> {
        Binding(
            get: { appState.config[keyPath: keyPath] },
            set: {
                appState.config[keyPath: keyPath] = $0
                ConfigManager.shared.save(appState.config)
            }
        )
    }
}
