# Spec 0081: GitHub Error Copy

## Objective

Keep GitHub provider failures accurate across notifications and repository
management instead of referring to one provider surface from every error.

## Requirements

- Shared GitHub client errors must use provider-level copy, not
  notification-specific copy.
- HTTP failures must include the returned status code.
- Existing GitHub create, delete, notification fetch, and mark-read call paths
  must keep using `GitHubClient`.

## Acceptance

- Error copy is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
