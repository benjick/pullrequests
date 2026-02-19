import SwiftUI

struct RepositoriesSettingsView: View {
    @Bindable var appState: AppState

    @State private var newRepoInput: String = ""
    @State private var isValidating = false
    @State private var validationError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Add repo section
            HStack {
                TextField("owner/repo", text: $newRepoInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addRepository() }

                Button(isValidating ? "Adding..." : "Add") {
                    addRepository()
                }
                .disabled(newRepoInput.isEmpty || isValidating || appState.token.isEmpty)
            }
            .padding()

            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            if appState.token.isEmpty {
                Text("Add a GitHub token in General settings first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            Divider()

            // Repo list
            if appState.config.repositories.isEmpty {
                VStack {
                    Spacer()
                    Text("No repositories configured")
                        .foregroundStyle(.secondary)
                    Text("Add repositories as owner/repo (e.g. apple/swift)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(appState.config.repositories) { repo in
                        HStack {
                            Image(systemName: "folder")
                                .foregroundStyle(.secondary)
                            Text(repo.id)

                            Spacer()

                            Button(action: { removeRepository(repo) }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func addRepository() {
        validationError = nil
        let input = newRepoInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let repo = Repository(fullName: input) else {
            validationError = "Invalid format. Use owner/repo"
            return
        }

        guard !appState.config.repositories.contains(repo) else {
            validationError = "Repository already added"
            return
        }

        isValidating = true

        Task {
            do {
                let service = GitHubService()
                let exists = try await service.validateRepository(repo, token: appState.token)
                if exists {
                    appState.config.repositories.append(repo)
                    ConfigManager.shared.save(appState.config)
                    newRepoInput = ""
                } else {
                    validationError = "Repository not found"
                }
            } catch {
                validationError = error.localizedDescription
            }
            isValidating = false
        }
    }

    private func removeRepository(_ repo: Repository) {
        appState.config.repositories.removeAll { $0 == repo }
        ConfigManager.shared.save(appState.config)
    }
}
