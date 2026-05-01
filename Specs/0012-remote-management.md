# Remote Management Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Expose repository remote management so users can add, update, and remove Git
remotes without leaving Bonsai.

## Requirements

- User can add a remote with name and URL.
- User can update an existing remote URL.
- User can remove a remote from the sidebar.
- Remote actions run through `GitClient`.
- Repository state refreshes after remote changes.

## Acceptance Checks

- Remote command methods are covered by integration tests.
- Views do not shell out directly.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
