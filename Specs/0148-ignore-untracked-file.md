# Spec 0148: Ignore Untracked File

## Objective

Let users ignore untracked files from Bonsai without leaving the working-tree
view or manually editing `.gitignore`.

## Requirements

- Untracked working-tree file rows expose `Ignore` from the row action menu and
  context menu.
- The Git command menu exposes `Ignore Selected File` when the selected
  working-tree entry is untracked.
- Ignoring a file appends a repository-root-relative pattern to `.gitignore`.
- Existing stage, discard, copy, open, reveal, blame, and file-history actions
  remain unchanged.
- The mutation routes through `RepositoryStore` and refreshes repository state.
- Tracked, staged, modified, deleted, and conflicted entries cannot be ignored
  through this action.
- Nested untracked files are listed as file paths instead of collapsed directory
  placeholders so they can be ignored individually.

## Acceptance

- Integration coverage proves ignoring an untracked file appends `.gitignore`
  and removes that file from status.
- Unit coverage proves ignore pattern formatting is repository-root-relative.
- `swift test`, the app verification script, and whitespace checks pass.
