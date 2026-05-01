# GitHub Notification Actions Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Make the GitHub notifications surface quiet and actionable by letting users mark
fetched notifications as read from Bonsai.

## Requirements

- User can mark GitHub notifications as read when a token is configured.
- Mark-read uses GitHub's notifications endpoint through `GitHubClient`.
- The sidebar notification count clears after a successful mark-read action.
- Failures surface in the command result area.

## Acceptance Checks

- Network calls remain isolated in `GitHubClient`.
- Views do not call the network directly.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
