# Spec 0071: Fetch Single Remote

## Objective

Let users fetch an individual remote from the remote sidebar instead of always
running a global fetch.

## Requirements

- Each remote row must expose a `Fetch` action in its context menu.
- Fetching a remote must run through `GitClient`, not the view layer.
- The command must prune stale remote-tracking refs for that remote.
- Repository state must refresh after the fetch completes.

## Acceptance

- Remote context menus include `Fetch` alongside edit and remove actions.
- Integration coverage proves fetching one configured remote updates
  remote-tracking refs.
- `swift test`, the app verification script, and whitespace checks pass.
