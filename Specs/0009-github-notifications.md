# GitHub Notifications Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Provide the v0 GitHub notification surface from Fork parity: let users fetch
their GitHub notification threads without leaving the Git client.

## Requirements

- User can configure a GitHub personal access token in Settings.
- Bonsai fetches unread notification threads from GitHub's REST API.
- Fetched notifications are summarized quietly in the sidebar and command result
  area.
- Notification fetching is isolated in a service; views do not call the network
  directly.

## API Notes

GitHub's official REST docs expose notifications as threads from the
authenticated user notifications endpoint. The endpoint supports polling and
requires a classic personal access token with `notifications` or `repo` scope.

Source: https://docs.github.com/v3/activity/notifications

## Acceptance Checks

- JSON decoding is unit-tested.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
