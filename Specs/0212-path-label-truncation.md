# Spec 0212: Path Label Truncation

## Intent

Keep file-path labels useful in compact panes by preserving filenames instead
of tail-truncating long repository paths.

## Requirements

- Working-tree row paths truncate in the middle and keep the full path in hover
  help.
- Commit changed-file rows truncate in the middle and keep rename context
  available through hover help.
- Diff detail titles and tree/blob path headers truncate in the middle.
- Do not add extra visible metadata or new controls.

## Acceptance

- Long source paths keep their filename visible in working-tree and changed-file
  lists.
- Full paths remain accessible through help text.
- SwiftPM build/tests, app verifier, and whitespace checks pass.
