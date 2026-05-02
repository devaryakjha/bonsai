# Spec 0084: Copy File Path Actions

## Objective

Make file-oriented rows expose the basic desktop Git-client action of copying
the repository-relative path without opening a secondary inspector.

## Requirements

- Working-tree file rows expose Copy Path from both the row action menu and the
  context menu.
- Commit changed-file rows expose Copy Path from the context menu.
- Commit tree rows expose Copy Path from the context menu.
- Rename rows may expose the previous path separately when Git reports one.
- Existing blame, file-history, reveal, stage, and tree navigation actions must
  keep their current behavior.
- Pasteboard writing should use one small app helper instead of duplicating
  `NSPasteboard` calls across views.

## Acceptance

- Path copy actions copy repository-relative paths.
- Commit hash copy actions continue to copy full hashes.
- `swift test`, the app verification script, and whitespace checks pass.
