# Branch Rename Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Complete the local branch management basics by allowing users to rename a local
branch without leaving Bonsai.

## Requirements

- Expose a Rename action from local branch context menus.
- Pre-fill the operation sheet with the selected branch name.
- Execute `git branch -m <old> <new>` through `GitClient`.
- Refresh repository refs after renaming.
- Keep checkout and delete behavior unchanged.

## Acceptance Checks

- Integration tests cover creating, renaming, listing, and deleting a local
  branch.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
