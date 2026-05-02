# Spec 0093: Reveal File Actions

## Objective

Make file-oriented rows expose the expected macOS desktop action for locating
repository files in Finder.

## Requirements

- Working-tree file rows route Reveal in Finder through the store instead of
  reaching into AppKit from row-local code.
- Commit and stash changed-file rows expose Reveal in Finder beside copy-path
  actions.
- Revealing a file uses the selected repository root plus the repository-relative
  path.
- Existing copy, blame, file-history, stage, and discard actions remain
  unchanged.

## Acceptance

- Working-tree and changed-file rows share the same reveal action path.
- Repository-relative path resolution is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
