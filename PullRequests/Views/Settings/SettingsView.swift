import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView(appState: appState)
                .tabItem { Label("General", systemImage: "gear") }

            RepositoriesSettingsView(appState: appState)
                .tabItem { Label("Repos", systemImage: "folder") }

            NotificationsSettingsView(appState: appState)
                .tabItem { Label("Notifications", systemImage: "bell") }

            FiltersSettingsView(appState: appState)
                .tabItem { Label("Filters", systemImage: "line.3.horizontal.decrease") }

            HiddenSettingsView(appState: appState)
                .tabItem { Label("Hidden", systemImage: "eye.slash") }
        }
        .frame(minWidth: 450, minHeight: 350)
    }
}
