# Spec 0051: Unified Diff Metadata Polish

## Objective

Keep commit and stash file review focused on the changed content by moving file
context into the detail header and removing raw patch file metadata from the
default unified diff body.

## Requirements

- When a commit or stash file is selected, the detail header must show the file
  path as the primary title.
- Commit or stash context must remain visible as secondary header text.
- Unified diff rendering must hide patch file metadata lines such as
  `diff --git`, `index`, `---`, and `+++`.
- Raw patch text must remain unchanged for copy-patch workflows.
- Split diff rendering must not change.

## Acceptance

- Commit and stash file review shows the selected file path without relying on
  patch metadata rows.
- Unified diff content starts at the meaningful hunk/body content for normal
  text diffs.
- `swift test`, the app verification script, and whitespace checks pass.
