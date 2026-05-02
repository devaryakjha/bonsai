# Spec 0107: Split Diff Path Context

## Objective

Make split diff mode easier to understand by showing the compared path context
inside each pane header.

## Requirements

- Split diff pane headers show both the side label and the path being compared.
- Renamed files show the original path on the old side and the new path on the
  new side.
- Added and deleted files label the missing side as `No file` instead of
  implying a path exists there.
- Working-tree diffs distinguish index, HEAD, and working-tree sides in the pane
  labels.
- Header text updates when the selected file changes without rebuilding the
  entire split renderer.
- Existing selectable text rendering, scroll synchronization, gutters, and
  inline highlights remain unchanged.

## Acceptance

- Split mode no longer shows anonymous Before/After panes for selected files.
- Rename diffs make the old and new paths visible without opening another
  surface.
- Added and deleted file diffs make the missing side explicit in the pane
  header.
- Pane context derivation is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
