# Spec 0211: Split Diff Missing Side Context

## Intent

Make split diff mode feel complete for added and deleted files by naming the
missing side directly in the pane header.

## Requirements

- Added files render the old pane header as `No file`.
- Deleted files render the new pane header as `No file`.
- Missing sides do not show a path detail because no file exists on that side.
- Preserve existing path context for modified and renamed files.
- Preserve selectable split diff text, gutters, scroll sync, and inline
  highlighting.

## Acceptance

- Working-tree split pane context covers staged added and deleted files.
- Commit/stash changed-file split pane context covers added and deleted files.
- Existing split pane context tests remain green.
- SwiftPM tests, app verifier, and whitespace checks pass.
