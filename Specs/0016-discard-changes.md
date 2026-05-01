# Discard Changes Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Support safe discard of selected working-tree changes with explicit
confirmation.

## Requirements

- User can discard a selected working-tree file.
- Discarding a tracked file restores it from Git.
- Discarding an untracked file removes it through Git.
- Discard always requires a confirmation sheet.
- Command output and failures appear in the command result area.

## Acceptance Checks

- Discard command lives in `GitClient`.
- Discard behavior is covered by integration tests.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
