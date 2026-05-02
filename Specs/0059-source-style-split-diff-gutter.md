# Spec 0059: Source-Style Split Diff Gutter

## Objective

Make split diff mode read like a side-by-side source view instead of two raw
patch columns.

## Requirements

- Split diff rows must render line numbers, a compact change marker, and source
  text as separate visual columns.
- Added and deleted rows must keep their semantic background color while hiding
  the raw `+` or `-` prefix from the source text column.
- Context and hunk header rows must remain aligned across both panes.
- Source lines that begin with header-like text such as `--flag` or `++value`
  must not be mistaken for patch metadata.
- Placeholder rows for one-sided additions/deletions must reserve bounded width
  without rendering raw patch markers.
- Inline word highlights must continue to align to the changed source text after
  the status marker moves into the gutter.

## Acceptance

- Split diff content no longer shows leading `+` or `-` inside the source text.
- The gutter still communicates additions and deletions.
- Header-like source text remains visible in split mode.
- Existing split-diff parser tests pass, with added coverage for display text
  and marker normalization.
- `swift test`, the app verification script, and whitespace checks pass.
