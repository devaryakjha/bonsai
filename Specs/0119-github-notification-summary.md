# Spec 0119: GitHub Notification Summary

## Objective

Keep fetched GitHub notification output quiet and bounded in the command result
area.

## Requirements

- Empty notification fetches show a concise empty result.
- Notification command output is capped to the first eight threads.
- Long notification lines are truncated with a clear suffix.
- Summary formatting lives outside the store network flow.

## Acceptance

- Unit tests cover empty, capped, and truncated notification summaries.
- Fetching notifications still uses `GitHubClient`.
- `swift test`, the app verification script, and whitespace checks pass.
