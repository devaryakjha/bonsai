# Spec 0301: Periodic Repository Refresh

## Objective

Refresh the visible repository snapshot when Git state changes outside Bonsai,
such as a commit made from Terminal.

## Requirements

- Periodic checks run only when `Auto refresh` is enabled.
- Checks use a cheap repository state token before running a full snapshot
  refresh.
- External commits on the current branch are detected without pressing
  `Refresh`.
- Manual `Refresh` keeps using `refreshAll()` directly.
- Background check failures do not interrupt the user; manual refresh remains
  the path that surfaces repository errors.

## Acceptance

- Store integration tests cover an external commit refreshing the visible
  history.
- Git command argument tests cover the repository state-token status command.
- `swift test` passes.
