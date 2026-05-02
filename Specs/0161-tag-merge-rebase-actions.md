# Spec 0161: Tag Merge and Rebase Actions

## Objective

Let users use tags as revision targets for merge and rebase operations from the
tag context menu.

## Requirements

- Tag context menus expose `Merge into Current Branch`.
- Tag context menus expose `Rebase Current onto Tag`.
- Both actions are disabled when there is no current local branch.
- Merge runs `git merge --no-edit <tag>` through `GitClient`.
- Rebase runs `git rebase <tag>` through `GitClient`.
- Successful operations refresh repository state and report through the existing
  command result surface.
- The commands stay behind the tag context menu so reference rows remain calm.

## Acceptance

- Integration coverage proves merging a tag keeps the current branch checked
  out and brings in the tag target changes.
- Integration coverage proves rebasing onto a tag keeps the current branch
  checked out and moves it onto the tag target.
- `swift test`, the app verifier, and whitespace checks pass.
