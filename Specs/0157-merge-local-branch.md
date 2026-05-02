# Spec 0157: Merge Local Branch

## Objective

Let users merge another local branch into the current branch directly from the
branch sidebar context menu.

## Requirements

- Local branch context menus expose `Merge into Current Branch`.
- The action is unavailable for the currently checked-out branch.
- The operation runs `git merge --no-edit <branch>` through `GitClient`.
- Successful merges refresh repository state and report through the existing
  command result surface.
- The command stays in the context menu so branch rows remain calm.

## Acceptance

- Integration coverage proves merging another local branch keeps the current
  branch checked out and brings in the source branch changes.
- `swift test`, the app verifier, and whitespace checks pass.
