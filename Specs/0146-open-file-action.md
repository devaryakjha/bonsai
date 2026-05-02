# Spec 0146: Open File Action

## Objective

Expose the standard macOS file action for opening repository files in their
default app without adding persistent row chrome.

## Requirements

- Working-tree file rows expose `Open` beside existing Copy Path and Reveal in
  Finder actions.
- Commit and stash changed-file rows expose `Open` from their context menu.
- Commit tree file rows expose `Open` from their context menu.
- The Git command menu exposes `Open Selected File` for the current selected
  file-like item.
- Opening a file routes through `RepositoryStore` and resolves paths from the
  selected repository root plus the repository-relative path.
- Failed open attempts surface command output instead of silently doing nothing.
- Existing copy-path, reveal, blame, file-history, stage, and discard actions
  remain unchanged.

## Acceptance

- Unit tests cover file-open URL resolution for repository-relative paths.
- `swift test`, the app verification script, and whitespace checks pass.
