# Spec 0149: Ignore Untracked File Extension

## Objective

Let users ignore a class of generated files from an untracked working-tree row
without manually editing `.gitignore`.

## Requirements

- Untracked working-tree file rows with an extension expose `Ignore Extension`
  from the row action menu and context menu.
- The Git command menu exposes `Ignore Selected File Extension` when the
  selected working-tree entry is untracked and has an extension.
- Ignoring an extension appends a file-extension pattern such as `*.log` to
  `.gitignore`.
- Entries without a file extension do not expose the extension ignore action.
- Existing single-file ignore, stage, discard, copy, open, reveal, blame, and
  file-history actions remain unchanged.
- The mutation routes through `RepositoryStore` and refreshes repository state.

## Acceptance

- Integration coverage proves ignoring an extension appends `.gitignore` and
  removes matching untracked files from status.
- Unit coverage proves extension pattern formatting.
- `swift test`, the app verification script, and whitespace checks pass.
