# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PullRequests is a macOS menu bar app for monitoring GitHub pull requests. Native Swift/SwiftUI app that lives in the menu bar with a popover dropdown — no dock icon, no main window. Uses GitHub GraphQL API (v4) for all data fetching.

## Build & Run

```bash
swift build                    # debug build
swift build -c release         # release build
swift run                      # run debug build
bash scripts/build-app.sh      # create .app bundle (release)

npm run dev                    # alias: swift build + run
npm run build                  # alias: release build
npm run install                # build + copy to /Applications
npm run clean                  # remove .build/
```

Requires Swift 5.9+, macOS 14+ (Sonoma).

## Architecture

### App Entry Point & Menu Bar Pattern

Follow the BreakTime pattern (`../breaktime/` for reference):
- `@main` App struct with `@NSApplicationDelegateAdaptor` bridging to AppKit
- `AppDelegate` is the central coordinator managing services and state
- `NSStatusItem` via `NSStatusBar.system` for the menu bar icon (not SwiftUI `MenuBarExtra`)
- Settings window uses `NSWindow` + `NSHostingView` to embed SwiftUI TabView in AppKit
- `LSUIElement: true` in Info.plist to hide from Dock
- Toggle activation policy between `.regular` (when settings window open) and `.accessory` (menu bar only)

### Popover UI

Unlike BreakTime (which uses NSMenu), this app uses a popover attached to the status item with two tabs:
- **My PRs** — PRs authored by the authenticated user
- **Needs Review** — PRs where user is requested reviewer or assigned

The menu bar icon shows a badge count for "Needs Review" items.

### Data Flow

- **GitHubService**: Single GraphQL query per poll using repository aliases to fetch all watched repos at once (~1-2 points per poll). PAT stored in macOS Keychain via `KeychainHelper`.
- **PollingService**: Default 30s interval with adaptive rate limiting (budget: 2500 GraphQL points/hour). Formula: `max(configured_interval, 3600 / (2500 / (repos * 2)))`.
- **NotificationService**: macOS native notifications for comments, review status changes, CI completion, and review requests. All individually toggleable. Bot comments filtered via configurable username blocklist.

### PR Context Menu (Right-Click)

- Open in GitHub, Copy URL, Mute PR (stops notifications but stays visible), Hide PR (removed from view, stored by PR number + repo in UserDefaults, unhideable in Settings)

### Settings Window

Tabbed settings (SwiftUI TabView in NSHostingView):
- **General**: PAT field, poll interval, launch at login
- **Repositories**: Add/remove watched repos with validation
- **Notifications**: Per-type toggles
- **Filters**: Bot username blocklist
- **Hidden**: Unhide previously hidden PRs

### Persistence

- **Keychain**: GitHub PAT
- **UserDefaults**: Repo list, notification prefs, hidden/muted PRs, bot blocklist, poll interval

## App Bundle Build

The `scripts/build-app.sh` script creates a proper macOS .app bundle:
1. `swift build -c release`
2. Creates `Contents/MacOS/`, `Contents/Resources/` structure
3. Copies binary, `Info.plist`, app icon, and `PkgInfo`

## File Structure Convention

```
PullRequests/
  Sources/
    App/           # @main entry, AppDelegate
    Models/        # Data models (PullRequest, Repository, Settings)
    Views/         # SwiftUI views (MenuBarView, PRRowView, SettingsView)
    Services/      # GitHubService, NotificationService, PollingService
    Utilities/     # KeychainHelper
```

## GraphQL Query Pattern

All repos fetched in a single query using aliases:
```graphql
query {
  repo0: repository(owner: "owner", name: "repo") {
    pullRequests(first: 30, states: OPEN) { ... }
  }
  repo1: repository(...) { ... }
}
```
