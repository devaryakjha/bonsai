# Git LFS Locking Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Expose Git LFS lock/unlock actions for selected files as part of the Fork parity
LFS workflow.

## Requirements

- User can lock the selected file when Git LFS is available.
- User can unlock the selected file when Git LFS is available.
- Locking commands run through `GitClient`.
- Command output and failures appear in the command result area.

## Acceptance Checks

- Views do not shell out directly.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
