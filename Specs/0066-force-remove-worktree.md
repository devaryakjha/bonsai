# Spec 0066: Force Remove Worktree

## Objective

Support force removal of worktrees while keeping the normal removal path safe.

## Requirements

- Worktree removal confirmation must expose an opt-in force remove toggle.
- Force remove must call `git worktree remove --force`.
- Opening a new worktree removal confirmation must reset the force option.
- The current repository worktree must remain unavailable for removal.

## Acceptance

- Normal worktree removal keeps using `git worktree remove`.
- Force worktree removal uses `git worktree remove --force`.
- Git client behavior is covered by integration tests.
- `swift test`, the app verification script, and whitespace checks pass.
