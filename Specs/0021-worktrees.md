# Worktrees Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Add modern Fork-style worktree awareness. Bonsai should show linked worktrees,
let users create a new worktree from the current revision, and remove linked
worktrees without leaving the app.

## Requirements

- Load worktrees with `git worktree list --porcelain`.
- Show each worktree path, HEAD, and branch/detached state in the sidebar.
- Expose a create worktree action that accepts a destination path and uses the
  selected commit when available, otherwise `HEAD`.
- Expose a remove worktree action for non-current worktrees.
- Refresh repository state after worktree mutations.

## Acceptance Checks

- Parser tests cover porcelain worktree output.
- Integration tests cover creating, listing, and removing a worktree.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
