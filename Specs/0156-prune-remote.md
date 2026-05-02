# Spec 0156: Prune Remote

## Objective

Expose a focused remote prune command for users who want to remove stale
remote-tracking refs without running a broader repository action.

## Requirements

- Remote context menus expose a `Prune` action.
- The action runs `git remote prune <remote>` through `GitClient`.
- The operation refreshes repository state and reports command output through
  the existing command result surface.
- The command stays in the context menu so the sidebar row remains calm.

## Acceptance

- A stale remote-tracking branch is removed after pruning its remote.
- `swift test`, the app verifier, and whitespace checks pass.
