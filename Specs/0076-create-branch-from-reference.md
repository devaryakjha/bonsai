# Spec 0076: Create Branch From Reference

## Objective

Let users create a new branch directly from an existing local branch, remote
branch, or tag in the sidebar.

## Requirements

- Local branch, remote branch, and tag context menus must expose
  `Create Branch from Here...`.
- The operation must use the selected reference as the new branch start point.
- Existing toolbar/history branch creation from selected commits or `HEAD` must
  keep working.
- Branch creation must still run through `RepositoryStore` and `GitClient`.

## Acceptance

- Sidebar references provide direct branch creation without requiring checkout
  first.
- Integration coverage proves local, remote, and tag refs can be used as branch
  start points.
- `swift test`, the app verification script, and whitespace checks pass.
