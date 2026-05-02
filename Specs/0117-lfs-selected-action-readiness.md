# Spec 0117: LFS Selected Action Readiness

## Objective

Make Git LFS selected-file actions predictable across working tree, history, and
commit-tree selections.

## Requirements

- Selected-file LFS actions stay disabled when Git LFS is unavailable.
- Selected-file LFS actions stay disabled when no previewable file is selected.
- Status, changed-file, and tree-entry selections each count as a selected file.
- Lock and unlock actions remain exposed through menus and command menus.

## Acceptance

- Store tests cover LFS selected-action readiness for unavailable LFS, no
  selection, and each supported file-selection source.
- Existing LFS commands remain behind `GitClient`.
- `swift test`, the app verification script, and whitespace checks pass.
