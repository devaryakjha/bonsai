# Spec 0105: Stage Commands

## Objective

Expose selected-file stage and unstage actions through the macOS Git command
menu while keeping selection state current after mutations.

## Requirements

- The Git command menu exposes Stage Selected File when the selected working-tree
  entry is unstaged.
- The Git command menu exposes Unstage Selected File when the selected
  working-tree entry is staged.
- Commands route through `RepositoryStore`, not directly through views.
- After staging or unstaging, the selected working-tree entry is reconciled to
  the refreshed snapshot so command enablement and diff state stay current.

## Acceptance

- Users can stage or unstage the selected file from the Git menu.
- The selected file remains selected after moving between staged and unstaged
  groups.
- Store behavior is covered by integration tests.
- `swift test`, the app verification script, and whitespace checks pass.
