# Spec 0163: Worktree Open Actions

## Objective

Make worktree rows easier to act on without adding visible row clutter.

## Requirements

- Worktree context menus expose `Reveal in Finder`.
- Worktree context menus expose `Open in Terminal`.
- Worktree path handling uses a typed URL helper instead of rebuilding file
  URLs ad hoc in views.
- Existing `Open Worktree`, `Copy Path`, and `Remove Worktree` actions remain
  available.

## Acceptance

- Unit coverage proves worktree directory URLs preserve the full filesystem
  path.
- `swift test`, the app verifier, and whitespace checks pass.
