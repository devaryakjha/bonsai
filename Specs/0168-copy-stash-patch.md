# Spec 0168: Copy Stash Patch

## Objective

Let users copy a complete stash patch for review, sharing, or manual apply
workflows without selecting each changed stash file.

## Requirements

- Stash row context menus expose `Copy Patch`.
- Toolbar stash menus expose `Copy Patch`.
- The action copies the full stash patch through Git instead of reconstructing
  patch text from visible rows.
- The action preserves existing apply, pop, branch, copy value, and drop stash
  actions.

## Acceptance

- Integration coverage proves a full stash patch includes changed file content.
- `swift test`, the app verifier, and whitespace checks pass.
