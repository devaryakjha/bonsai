# Spec 0158: Rebase Current Branch

## Objective

Let users rebase the current branch onto another local branch from the branch
sidebar context menu.

## Requirements

- Local branch context menus expose `Rebase Current onto Branch`.
- The action is unavailable for the currently checked-out branch.
- The operation runs `git rebase <branch>` through `GitClient`.
- Successful rebases refresh repository state and report through the existing
  command result surface.
- The command stays in the context menu so branch rows remain calm.

## Acceptance

- Integration coverage proves the current branch stays checked out and is
  rebased onto the selected branch.
- `swift test`, the app verifier, and whitespace checks pass.
