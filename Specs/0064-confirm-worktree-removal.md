# Spec 0064: Confirm Worktree Removal

## Objective

Prevent accidental worktree removal from the sidebar.

## Requirements

- Removing a non-current worktree must open a confirmation sheet before running
  Git.
- The sheet must name the worktree and show its full path.
- The current repository worktree must remain unavailable for removal.
- The existing create and open worktree flows must keep their current behavior.

## Acceptance

- The worktree context-menu `Remove worktree` action no longer calls the
  mutation directly.
- The destructive confirmation button is the only UI path that calls
  `git worktree remove`.
- Remove request copy is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
