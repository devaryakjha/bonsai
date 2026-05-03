# Commit Detail Performance

## Intent

Commit selection must feel immediate. Bonsai should not spend energy loading
secondary commit detail surfaces or stale selection results when the user is
moving through history.

## Requirements

- Selecting a commit refreshes only the changed-file list and selected-file diff
  needed for the default detail surface.
- Commit tree browsing loads on demand when the user opens the Tree panel.
- Immutable commit changed-file and diff reads are cached by commit/file/options
  for the active repository.
- A newer commit selection cancels stale commit-detail work before it can update
  the UI.
- Cancelled Git subprocesses are terminated instead of being allowed to burn CPU
  in the background.
- AppKit bridge observers used by rich diff surfaces are removed with their
  coordinators so repeated diff view creation does not leak notification
  tokens.
- Commit rows use static date strings instead of SwiftUI live relative-date text;
  seconds are shown only for sub-minute commits.

## Acceptance

- Store coverage proves commit tree loading is lazy and still available on
  demand.
- Process coverage proves cancellation terminates a long-running subprocess.
- Date-copy coverage proves history rows do not schedule per-second updates for
  older commits.
- Existing integration coverage for commit selection, changed files, and diffs
  remains green.
