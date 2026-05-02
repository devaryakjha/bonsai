# Spec 0138: Split Diff Shared Gutter Width

## Objective

Make split diff mode feel like one side-by-side source review surface by aligning
the source columns across both panes.

## Requirements

- Split diff rendering uses one shared line-number gutter width for the old and
  new panes.
- The shared width is derived from the largest visible line number across both
  sides.
- The gutter keeps a minimum width for small files.
- Existing path headers, scroll synchronization, replacement pairing, and inline
  highlights remain unchanged.

## Acceptance

- Split diffs with different old/new line-number digit counts keep matching
  source-column offsets.
- Shared gutter width is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
