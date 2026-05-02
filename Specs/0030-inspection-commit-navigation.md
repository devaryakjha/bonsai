# Inspection Commit Navigation Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Make structured inspection sheets part of the main revision workflow. Blame and
file-history views should let users jump to the commit they are inspecting
instead of forcing them to copy a hash and search manually.

## Requirements

- Add a Git-backed way to resolve a commit by hash outside the currently loaded
  history window.
- Add an action from file history rows to select that commit in the main history
  mode.
- Add an action from blame rows to select that line's commit in the main history
  mode.
- Close the inspection sheet after a successful jump and refresh commit files,
  tree entries, and diff state for the selected revision.
- Preserve existing raw diagnostic commands and current history selection
  behavior.

## Acceptance Checks

- Integration tests cover resolving a commit by hash.
- Store tests or integration coverage prove the jump selects the target commit.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
