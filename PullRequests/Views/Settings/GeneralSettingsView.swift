import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var appState: AppState

    @State private var tokenInput: String = ""
    @State private var isValidating = false
    @State private var validationMessage: String?
    @State private var validationSuccess = false

    private let keychainHelper = KeychainHelper()

    var body: some View {
        Form {
            Section("GitHub Personal Access Token (classic)") {
                SecureField("ghp_...", text: $tokenInput)
                    .textFieldStyle(.roundedBorder)
                    .onAppear {
                        tokenInput = appState.token
                    }

                HStack {
                    Button(isValidating ? "Validating..." : "Validate Token") {
                        validateToken()
                    }
                    .disabled(tokenInput.isEmpty || isValidating)

                    if let message = validationMessage {
                        Image(systemName: validationSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(validationSuccess ? .green : .red)
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(validationSuccess ? .green : .red)
                    }
                }

                if !appState.authenticatedUsername.isEmpty {
                    Text("Authenticated as **\(appState.authenticatedUsername)**")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Requires the **repo** scope (or **public_repo** for public repos only).")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Link("Generate a classic token on GitHub",
                     destination: URL(string: "https://github.com/settings/tokens")!)
                    .font(.caption)
            }

            Section("Polling") {
                Picker("Poll interval", selection: Binding(
                    get: { Int(appState.config.pollInterval) },
                    set: {
                        appState.config.pollInterval = TimeInterval($0)
                        ConfigManager.shared.save(appState.config)
                    }
                )) {
                    Text("15 seconds").tag(15)
                    Text("30 seconds").tag(30)
                    Text("60 seconds").tag(60)
                    Text("2 minutes").tag(120)
                    Text("5 minutes").tag(300)
                }
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: Binding(
                    get: { LaunchAtLoginManager.shared.isEnabled },
                    set: { _ in LaunchAtLoginManager.shared.toggle() }
                ))
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func validateToken() {
        isValidating = true
        validationMessage = nil

        Task {
            do {
                let service = GitHubService()
                let username = try await service.validateToken(tokenInput)
                appState.authenticatedUsername = username
                appState.token = tokenInput
                let _ = keychainHelper.save(token: tokenInput)
                validationMessage = "Authenticated as \(username)"
                validationSuccess = true
                NotificationCenter.default.post(name: .tokenChanged, object: nil)
            } catch {
                validationMessage = error.localizedDescription
                validationSuccess = false
            }
            isValidating = false
        }
    }
}
