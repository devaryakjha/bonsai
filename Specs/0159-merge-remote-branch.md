# Spec 0159: Merge Remote Branch

## Objective

Let users merge a remote-tracking branch into the current branch from the
remote branch context menu.

## Requirements

- Remote branch context menus expose `Merge into Current Branch`.
- The action is disabled when there is no current local branch.
- Symbolic remote `HEAD` rows are not treated as merge targets.
- The operation runs `git merge --no-edit <remote-branch>` through `GitClient`.
- Successful merges refresh repository state and report through the existing
  command result surface.
- The command stays behind the remote branch disclosure and context menu.

## Acceptance

- Integration coverage proves merging a remote-tracking branch keeps the
  current branch checked out and brings in the remote branch changes.
- `swift test`, the app verifier, and whitespace checks pass.
