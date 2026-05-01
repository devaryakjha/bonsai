# Interactive Rebase Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Expose a visual interactive rebase flow for the recent commits on the current
branch, matching the core Fork promise: edit, reorder, and squash commits
without manually editing Git's todo file.

## Requirements

- Bonsai can prepare an interactive rebase todo plan from recent branch commits.
- Each todo row can be changed between pick, reword, edit, squash, fixup, and drop.
- Rows can be moved up and down before execution.
- Execution uses Git's native `rebase -i` machinery through `GIT_SEQUENCE_EDITOR`.
- Command output and failures are surfaced in the existing command result area.

## Acceptance Checks

- Todo text generation is unit-tested.
- Rebase execution is isolated in `GitClient`.
- Views do not shell out directly.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
