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
bash scripts/install.sh        # build + copy to /Applications (do NOT use npm run install)
npm run clean                  # remove .build/
```

Requires Swift 5.9+, macOS 14+ (Sonoma).

## Architecture

### App Entry Point & Menu Bar Pattern

Follow the BreakTime pattern (`../breaktime/` for reference):
- `@main` App struct (`App/PullRequestsApp.swift`) with `@NSApplicationDelegateAdaptor` bridging to AppKit; its only scene is an empty `Settings {}`
- `AppDelegate` is the central coordinator managing services and state
- `NSStatusItem` via `NSStatusBar.system` for the menu bar icon (not SwiftUI `MenuBarExtra`), managed by `MenuBar/MenuBarController.swift`. Left-click toggles the popover; right-click shows a small menu (Refresh, Settings…, Quit)
- Settings window: `MenuBar/SettingsWindowController.swift` builds an `NSWindow` around a toolbar-style `NSTabViewController`, each tab an `NSHostingController` with a SwiftUI settings view. Don't go back to a SwiftUI `TabView` in an `NSWindow`: on macOS 26 its tabs collapse into a `>>` overflow menu. Give each hosting controller a `title`, or the window says "Untitled"
- `LSUIElement: true` in Info.plist to hide from Dock
- Toggle activation policy between `.regular` (when settings window open) and `.accessory` (menu bar only)

### Popover UI

Unlike BreakTime (which uses NSMenu), this app uses a transient `NSPopover` (`MenuBar/PopoverController.swift`) attached to the status item, showing `Views/PopoverContentView.swift`. It's a single scrolling list with up to three sections (empty ones are hidden):
- **Ready to Merge**: the user's own PRs whose review status is approved
- **Needs Your Review**: other people's PRs where the user is a requested reviewer, or where the user's latest review is only a comment
- **Waiting for Review**: the user's own PRs that aren't approved yet

The footer shows the last update time, an error indicator, the "Update available" pill (see UpdateChecker under Data Flow), and Refresh / Settings / Quit buttons.

The menu bar icon shows up to two badges: green for Ready to Merge, plus the count of Needs Your Review PRs that aren't approved.

### Data Flow

- **GitHubService**: Single GraphQL query per poll using repository aliases to fetch all watched repos at once (~1-2 points per poll).
- **PollingService**: Validates the token (`viewer { login }`) to learn the username, then polls. Default 30s interval with adaptive rate limiting (budget: 2500 GraphQL points/hour). Formula: `max(configured_interval, 3600 / (2500 / (repos * 2)))`. Every poll re-validates while the username is still unknown, and failures other than 401 reschedule the next poll, so a launch before the network is up recovers on its own.
- **PRDiffEngine**: Compares the previous and current poll to produce changes (new comments, review status changes, CI finished, review requested).
- **NotificationService**: macOS native notifications for those changes, each type toggleable. Comment notifications fire for new comments on any watched PR (not only the user's own), skipping the user's own comments and bots that aren't allowed. Review status and CI notifications are only for the user's own PRs. Bots are discovered from comment authors and ignored by default (`AppConfig.allowedBots` opts them in).
- **UpdateChecker**: At launch and every 6 hours, fetches `api.github.com/repos/benjick/pullrequests/releases` (unauthenticated) and stores every release newer than the running version, with parsed notes, in `AppState.availableUpdate` / `updateNotes`. Skipped when the bundle version isn't numeric (local `dev` builds).
- **Logging**: `os.Logger` with subsystem `com.pullrequests.app` (categories `polling`, `updates`). Read with `log show --info --predicate 'subsystem == "com.pullrequests.app"'`.

### PR Context Menu (Right-Click)

- Open in GitHub, Copy URL, Mute PR (stops notifications but stays visible), Hide PR (removed from view, stored by PR number + repo in UserDefaults, unhideable in Settings)

### Settings Window

Toolbar tabs (see the settings window note above):
- **General**: PAT field, poll interval, launch at login, About (version and GitHub link)
- **Repositories**: Add/remove watched repos with validation
- **Notifications**: Per-type toggles
- **Filters**: Discovered bot accounts, each set to Ignore (default) or Allow
- **Hidden**: Unhide previously hidden PRs

### Persistence

- **Token file**: the GitHub PAT lives in `~/.config/pullrequests/token` (mode 0600), read and written by `Utilities/KeychainHelper.swift` (the name is historical; it no longer uses the Keychain, because ad-hoc signed builds change signature on every build and triggered Keychain prompts)
- **UserDefaults**: one JSON-encoded `AppConfig` under the key `com.pullrequests.config`: repo list, poll interval, notification toggles, discovered and allowed bots, hidden and muted PRs (stored as `owner/repo#number`)

## Releases, Changelog & Store Listing

Releases are distributed through Homebrew (`brew install --cask benjick/tap/pullrequests`)
and built by the shared workflow in `benjick/homebrew-tap` when a `v*` tag is pushed.

- **Changelog:** before tagging, add a `## <version> - <date>` section at the top of
  `CHANGELOG.md`. It becomes the GitHub release notes and the in-app "what's new"; the
  release fails without it.
- **Tags must be annotated:** `git tag -a v1.2.3 -m "PullRequests 1.2.3" && git push origin v1.2.3`.
- **Test UI changes locally before pushing.** Local builds report version `dev`, which
  skips the update check; to see update UI, stamp a copy of the built app with an older
  version (`PlistBuddy -c "Set :CFBundleShortVersionString 1.0.0"`, then re-sign with
  `codesign --force --deep --sign -`) and run that.

### Store listing: keep `docs/store.md` in sync

`docs/store.md` is the app's page on malm.me/apps (built by `benjick/malm.me` from this
repo's default branch, together with `docs/icon.png`, `docs/screenshots/*.png`,
`CHANGELOG.md` and the GitHub releases).

**Whenever a change affects what a user would read there, update `docs/store.md` in the
same commit**: features added, removed or changed, setup steps, settings, requirements
(macOS version, architecture), install command, or the app's name or tagline. Describe
what the code actually does, not what a label says. Also keep `README.md` consistent with
it; they share most of their content.

Related files:
- `docs/icon.png` is written by `scripts/generate-icon.swift` alongside `AppIcon.icns`.
  Regenerate both together; never edit one by hand.
- `docs/screenshots/*.png` are shown in filename order and the filename is the alt text,
  so name them `01-<what-it-shows>.png`, `02-…`. Retake them when the UI they show
  changes, and never include private repository names or PR titles.

## App Bundle Build

The `scripts/build-app.sh` script creates a proper macOS .app bundle:
1. `swift build -c release`
2. Creates `Contents/MacOS/`, `Contents/Resources/` structure
3. Copies binary, `Info.plist`, app icon, and `PkgInfo`
4. Ad-hoc signs the bundle

`Info.plist` keeps `CFBundleShortVersionString` at `dev`; the release workflow overwrites it from the tag and re-signs.

## File Structure

```
PullRequests/          # all app source (SwiftPM target root; there is no Sources/ folder)
  App/                 # @main entry (PullRequestsApp), AppDelegate
  MenuBar/             # MenuBarController, PopoverController, SettingsWindowController
  Models/              # AppConfig, AppState, PullRequest, Repository
  Services/            # GitHubService, PollingService, PRDiffEngine, NotificationService,
                       # UpdateChecker, ConfigManager, LaunchAtLoginManager
  Utilities/           # KeychainHelper (token file, despite the name)
  Views/               # PopoverContentView, PRRowView, Components/, Settings/
  Resources/           # AppIcon.icns
  Info.plist
scripts/               # build-app.sh, install.sh, generate-icon.swift
docs/                  # store.md, icon.png, screenshots/ (store listing)
.github/workflows/     # release.yml (calls benjick/homebrew-tap's shared workflow)
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
