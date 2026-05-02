# Spec 0134: Worktree Branch Creation

## Objective

Let users create a worktree as a new branch instead of only creating detached
worktrees.

## Requirements

- The create-worktree flow must collect a destination path.
- The flow must also expose an optional new branch field.
- Leaving the branch field empty must preserve the existing detached worktree
  behavior.
- Entering a branch name must run `git worktree add -b <branch> <path>
  <start-point>` through `GitClient`.
- The selected history commit remains the start point when present; otherwise
  the start point is `HEAD`.

## Acceptance

- Detached worktree creation continues to work.
- Branch worktree creation checks out the new branch in the created worktree.
- Repository state refreshes after creating either kind.
- `swift test`, the app verification script, and whitespace checks pass.
