---
# The app's listing on malm.me/apps. benjick/malm.me reads this file, plus
# docs/icon.png, docs/screenshots/*.png (in filename order), CHANGELOG.md and
# the GitHub releases, when it builds. Changes show up on its next deploy.
# Keep it in sync with the app: see "Store listing" in CLAUDE.md.
name: PullRequests
tagline: Keep track of GitHub pull requests
category: Developer Tools
cask: pullrequests
minimumMacOS: "14"
menuBar: true
bundleId: com.pullrequests.app
# Optional, for the featured card on the store's front page.
headline: Never miss a review again.
color: "#6659E6"
---

A macOS menu bar app for keeping track of GitHub pull requests. It shows the
PRs that need your attention in a popover, badges the menu bar icon with how
many are waiting on you, and sends native notifications when something
changes.

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

## Getting started

1. Install with `brew install --cask benjick/tap/pullrequests` and launch
   PullRequests. It lives in the menu bar; there's no Dock icon.
2. Open Settings from the gear icon in the popover.
3. **General:** paste a GitHub [personal access token (classic)](https://github.com/settings/tokens/new?scopes=repo&description=PullRequests)
   with the `repo` scope (or `public_repo` if you only watch public repos) and
   click **Validate Token**.
4. **Repos:** add the repositories to watch, as `owner/name`.

The token is stored in `~/.config/pullrequests/token`, readable only by your
user. If your organisation uses SAML single sign-on, authorise the token for
it on GitHub (Settings → Developer settings → Tokens → Configure SSO), or the
org's repositories won't show up.

Requires macOS 14 (Sonoma) or later on Apple Silicon.
