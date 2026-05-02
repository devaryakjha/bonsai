# Spec 0152: Rename Tag

## Objective

Complete the local tag management basics by allowing users to rename an
existing tag without leaving Bonsai.

## Requirements

- Tag context menus expose `Rename...`.
- The rename sheet is prefilled with the selected tag name.
- Renaming must preserve the original tag object so annotated tags do not become
  lightweight tags.
- The action routes through `RepositoryStore` and `GitClient`.
- Successful renames refresh repository refs through the existing mutation
  pipeline and command result surface.
- Existing tag checkout, branch creation, push, copy, and delete actions remain
  unchanged.

## Acceptance

- Renaming an annotated tag moves the tag ref to the new name while preserving
  the original annotated tag object.
- The old tag ref is removed after the new tag ref is created.
- `swift test`, the app verification script, and whitespace checks pass.
