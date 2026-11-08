# Changelog

Each release's section is used as its GitHub release notes. Add a section
for the new version before pushing its tag; the release fails without one.

## 1.0.4 - 2026-11-08

- Tighten the spacing between the icon and text of the "Update available"
  button.

## 1.0.3 - 2026-11-08

- Fix the "Version" label in Settings → General.

## 1.0.2 - 2026-11-08

- Check GitHub for new releases at launch and every 6 hours. When one is
  available, the popover footer shows **Update available**, which expands to
  the `brew upgrade` command with a Copy button.

## 1.0.1 - 2026-11-08

- Show the app version in Settings → General, with a link to the GitHub repo.
- Show the selected tab's name as the Settings window title instead of
  "Untitled".
- Add the MIT license and a README covering install, setup and uninstall.

## 1.0.0 - 2026-11-08

First release through Homebrew: `brew install --cask benjick/tap/pullrequests`.

- Retry when GitHub can't be reached at launch (for example when the app
  starts at login before Wi-Fi connects). Previously polling stopped and PRs
  never appeared until the app was restarted.
- Fix the Settings tabs collapsing into a `>>` overflow menu on macOS 26.
- Log polling activity and errors to the unified log under
  `com.pullrequests.app`.
