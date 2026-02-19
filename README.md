# PullRequests

A macOS menu bar app for monitoring GitHub pull requests. It polls the GitHub GraphQL API across your configured repos and shows your open PRs and pending reviews in a popover dropdown, with native macOS notifications for comments, reviews, CI status, and review requests.

## Dev Install

```bash
git clone https://github.com/benjick/pullrequests.git && cd pullrequests
bash scripts/build-app.sh
cp -r .build/release/PullRequests.app /Applications/
```
