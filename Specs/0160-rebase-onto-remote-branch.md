# Spec 0160: Rebase onto Remote Branch

## Objective

Let users rebase the current branch onto a remote-tracking branch from the
remote branch context menu.

## Requirements

- Remote branch context menus expose `Rebase Current onto Branch`.
- The action is disabled when there is no current local branch.
- Symbolic remote `HEAD` rows are not treated as rebase targets.
- The operation runs `git rebase <remote-branch>` through `GitClient`.
- Successful rebases refresh repository state and report through the existing
  command result surface.
- The command stays behind the remote branch disclosure and context menu.

## Acceptance

- Integration coverage proves rebasing onto a remote-tracking branch keeps the
  current branch checked out and moves it onto the remote branch.
- `swift test`, the app verifier, and whitespace checks pass.
