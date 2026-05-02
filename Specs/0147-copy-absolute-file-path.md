# Spec 0147: Copy Absolute File Path

## Objective

Add the standard desktop file action for copying an absolute worktree path while
preserving the existing repository-relative `Copy Path` behavior.

## Requirements

- Working-tree file rows expose `Copy Absolute Path` beside existing file
  actions.
- Commit and stash changed-file rows expose `Copy Absolute Path` from their
  context menu.
- Commit tree rows expose `Copy Absolute Path` from their context menu.
- The toolbar actions menu exposes `Copy Selected File Absolute Path` for the
  current selected file-like item.
- Absolute paths resolve from the selected repository root plus the
  repository-relative path.
- Existing `Copy Path` actions continue to copy repository-relative paths.

## Acceptance

- Unit tests cover absolute path resolution for repository-relative paths.
- `swift test`, the app verification script, and whitespace checks pass.
