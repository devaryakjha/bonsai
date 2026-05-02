# Spec 0139: History Graph Column Width

## Objective

Make the history graph lane feel like a real Git graph column by avoiding
clipped graph text on wider branch topologies.

## Requirements

- Commit rows derive their graph column width from the currently displayed
  commits.
- The graph column keeps a stable minimum width for simple linear histories.
- Wider Git graph lane text expands the column instead of truncating the lane.
- Commit details stay aligned with the same graph column width.
- Existing search, selection, context menus, and optional row details remain
  unchanged.

## Acceptance

- Graph column character sizing is covered by unit tests.
- Simple histories keep the compact existing width.
- Wider graph lane text gets enough column width before the subject.
- `swift test`, the app verification script, and whitespace checks pass.
