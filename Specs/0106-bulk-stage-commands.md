# Spec 0106: Bulk Stage Commands

## Objective

Expose Fork-style bulk stage and unstage actions for the working tree while
keeping conflict handling explicit.

## Requirements

- The Git command menu exposes Stage All when there are unstaged,
  non-conflicted working-tree changes.
- The Git command menu exposes Unstage All when there are staged changes.
- Stage All stages modified, deleted, and untracked paths without staging
  conflicted paths.
- Unstage All works for normal repositories and unborn repositories with staged
  files.
- Commands route through `RepositoryStore` and `GitClient`; views do not shell
  out directly.

## Acceptance

- Users can stage all non-conflicted changes from the Git menu.
- Users can unstage all staged changes from the Git menu.
- Bulk staging refreshes working-tree groups and selected diff state through the
  normal mutation path.
- Store behavior is covered by integration tests.
- `swift test`, the app verification script, and whitespace checks pass.
