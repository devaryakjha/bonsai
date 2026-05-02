# Spec 0097: Workspace Repository Actions

## Objective

Give scanned `~/projects` repositories the same opt-in path actions as recents
without making the workspace browser noisy.

## Requirements

- Workspace repository rows keep their compact name-only presentation.
- Workspace repository rows expose the full path through hover help.
- Workspace repository context menus expose Copy Path and Reveal in Finder.
- Opening a workspace repository continues to record it in recents.
- Actions route through `RepositoryStore`.

## Acceptance

- Users can copy or reveal a scanned workspace repository without first opening
  it.
- Workspace rows do not show full filesystem paths by default.
- `swift test`, the app verification script, and whitespace checks pass.
