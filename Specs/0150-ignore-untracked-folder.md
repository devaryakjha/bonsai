# Spec 0150: Ignore Untracked Folder

## Objective

Let users ignore the containing folder of an untracked generated file from
Bonsai without manually editing `.gitignore`.

## Requirements

- Untracked working-tree file rows inside a folder expose `Ignore Folder` from
  the row action menu and context menu.
- The Git command menu exposes `Ignore Selected File Folder` when the selected
  working-tree entry is untracked and has a containing folder.
- Ignoring a folder appends a repository-root-relative folder pattern such as
  `/Logs/` to `.gitignore`.
- Root-level untracked files do not expose the folder ignore action.
- Existing single-file ignore, extension ignore, stage, discard, copy, open,
  reveal, blame, and file-history actions remain unchanged.
- The mutation routes through `RepositoryStore` and refreshes repository state.

## Acceptance

- Integration coverage proves ignoring a folder appends `.gitignore` and removes
  matching untracked files from status.
- Unit coverage proves folder pattern formatting.
- `swift test`, the app verification script, and whitespace checks pass.
