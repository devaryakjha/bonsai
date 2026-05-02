# Spec 0043: Split Diff Line Gutters

## Objective

Make split diff mode feel complete and scannable without adding heavy chrome or
always-on explanatory UI.

## Requirements

- Split diff parsing must keep aligned old/new rows with side-specific line
  numbers.
- Deleted lines must show only an old-side line number.
- Added lines must show only a new-side line number.
- Context lines must show both old and new line numbers.
- Hunk rows must remain aligned without line numbers.
- The split diff renderer must show a quiet gutter for line numbers on both
  panes while preserving inline change highlights.

## Acceptance

- Parser tests verify old/new line-number alignment.
- Split diff mode renders line-number gutters in both panes.
- `swift test` and the app verification script pass.
