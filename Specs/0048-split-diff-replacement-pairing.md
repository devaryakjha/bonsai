# Spec 0048: Split Diff Replacement Pairing

## Objective

Make split diff mode behave like a complete side-by-side reviewer by pairing
replacement lines across the before and after panes instead of rendering them as
separate one-sided rows.

## Requirements

- Adjacent deletion/addition blocks in a hunk must be aligned by row in split
  mode.
- Paired replacement rows must keep old and new line numbers on the same row.
- Extra deleted lines must remain old-side-only rows.
- Extra added lines must remain new-side-only rows.
- Inline changed-range highlighting must work on paired replacement rows.
- One-sided placeholder rows must be visually distinct without adding visible
  explanatory copy.

## Acceptance

- Parser tests verify paired replacement rows and leftover one-sided rows.
- Split diff rendering keeps synchronized panes, gutters, and inline
  highlighting.
- `swift test`, the app verification script, and whitespace checks pass.
