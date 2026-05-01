# Revision and Commit Polish Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Close two practical parity gaps in the everyday Git workflow: reset selected
revisions and reuse recent commit messages.

## Requirements

- User can reset to the selected commit with soft, mixed, or hard mode.
- Reset requires an explicit sheet confirmation.
- User can reuse recent commit messages from the commit composer.
- Recent commit messages are stored locally and capped.
- Reset and commit operations refresh repository state.

## Acceptance Checks

- Reset command lives in `GitClient`.
- Recent message persistence is store-owned, not view-owned.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
