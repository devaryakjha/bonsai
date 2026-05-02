# Spec 0077: Create Tag From Reference

## Objective

Let users create tags directly from local and remote branch references in the
sidebar without checking those branches out first.

## Requirements

- Local branch and remote branch context menus must expose `Create Tag Here...`.
- The operation must use the selected branch reference as the tag target.
- Existing toolbar/history tag creation from selected commits or `HEAD` must keep
  working.
- Tag creation must still run through `RepositoryStore` and `GitClient`.

## Acceptance

- Sidebar branch references provide direct tag creation.
- Integration coverage proves local and remote branch refs can be used as tag
  targets.
- `swift test`, the app verification script, and whitespace checks pass.
