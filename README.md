# PullRequests

A macOS menu bar app for keeping track of GitHub pull requests. It shows the
PRs that need your attention in a popover, with a badge count on the menu bar
icon, and sends native notifications for new comments, review changes,
finished CI runs and review requests.

<p>
  <img src="docs/screenshots/01-settings-general.png" width="32%" alt="General settings">
  <img src="docs/screenshots/02-settings-notifications.png" width="32%" alt="Notification settings">
  <img src="docs/screenshots/03-settings-filters.png" width="32%" alt="Bot filters">
</p>

## Install

```sh
brew install --cask benjick/tap/pullrequests
```

Update with `brew upgrade`.

Requires macOS 14 (Sonoma) or later on Apple Silicon.

The app is ad-hoc signed rather than notarised by Apple. The Homebrew cask
clears the quarantine flag on install so it opens normally. If you download
the zip from the releases page instead, macOS will refuse to open it until you
allow it in System Settings → Privacy & Security.

## Setup

1. Launch PullRequests. It lives in the menu bar; there's no Dock icon.
2. Open Settings from the gear icon in the popover.
3. **General:** paste a GitHub [personal access token (classic)](https://github.com/settings/tokens/new?scopes=repo&description=PullRequests)
   with the `repo` scope (or `public_repo` if you only watch public repos) and
   click **Validate Token**.
4. **Repos:** add the repositories to watch, as `owner/name`.

The token is stored in `~/.config/pullrequests/token`, readable only by your
user.

If your organisation uses SAML single sign-on, authorise the token for it on
GitHub (Settings → Developer settings → Tokens → Configure SSO), or the org's
repositories won't show up.

## Features

- One popover grouped into **Ready to Merge** (your approved PRs), **Needs
  Your Review** and **Waiting for Review** (your PRs still in review), with CI
  and review status on each PR.
- Menu bar badges: green for your PRs that are ready to merge, plus a count of
  reviews waiting on you.
- Notifications for new comments on watched PRs, review status changes and
  finished CI runs on your PRs, and new review requests. Each type can be
  turned off.
- Bot accounts are discovered from PR comments and ignored by default; allow
  the ones whose comments you want to be notified about.
- Right-click a PR to open it, copy its URL, mute its notifications or hide
  it. Hidden PRs can be brought back in Settings.
- Polls every 30 seconds by default (15 seconds to 5 minutes), backing off
  automatically to stay within GitHub's API rate limits when you watch many
  repositories. Keeps retrying if GitHub can't be reached, for example right
  after login.
- Tells you when a new version is out, shows what's new, and gives you the
  `brew upgrade` command.

## Uninstall

```sh
brew uninstall --cask pullrequests          # remove the app
brew uninstall --cask --zap pullrequests    # also remove the token and settings
```

## Building from source

Requires Xcode or the Command Line Tools with Swift 5.9+.

```sh
git clone https://github.com/benjick/pullrequests.git && cd pullrequests
bash scripts/install.sh    # builds and copies PullRequests.app to /Applications
```

Local builds show version `dev` in Settings → General. Releases are built by
GitHub Actions when a `v*` tag is pushed and published to
[benjick/homebrew-tap](https://github.com/benjick/homebrew-tap).

## License

[MIT](LICENSE)
