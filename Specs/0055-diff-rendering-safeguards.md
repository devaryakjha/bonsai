# Spec 0055: Diff Rendering Safeguards

## Objective

Keep rich diff rendering responsive on large or generated changes by bounding
expensive presentation-only work while preserving raw patch content and Git's
selected diff algorithm.

## Requirements

- Inline word-level highlighting must be skipped for very long changed line
  pairs.
- Split-diff placeholder rows must use a bounded visual width instead of
  repeating extremely long counterpart lines.
- Raw diff text and copy-patch behavior must remain unchanged.
- Git diff generation must continue to use the selected Git diff algorithm.
- Rendering safeguards must be covered by unit tests.

## Acceptance

- Long minified-line changes do not trigger inline highlight calculation.
- Split placeholders remain useful but cannot allocate unbounded padding for a
  single long counterpart line.
- `swift test`, the app verification script, and whitespace checks pass.
