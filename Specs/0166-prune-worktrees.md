# Spec 0166: Prune Worktrees

## Objective

Let users clean stale worktree metadata from Bonsai without opening a terminal,
while keeping worktree rows visually calm.

## Requirements

- Bonsai exposes `Prune Worktrees` from menu-driven surfaces instead of adding
  inline controls to each worktree row.
- The action runs `git worktree prune` through `GitClient`.
- Worktree pruning refreshes repository state after completion.
- Existing create, open, reveal, terminal, copy, and remove worktree actions
  remain available.

## Acceptance

- Integration coverage proves a missing linked worktree is removed from
  `git worktree list --porcelain` after pruning.
- `swift test`, the app verifier, and whitespace checks pass.
