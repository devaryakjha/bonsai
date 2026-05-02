# Spec 0052: In-view Copy Case

## Objective

Keep product copy aligned with Bonsai's interface standards by using sentence
case for visible in-window controls, sheets, empty states, and command feedback.

## Requirements

- In-view buttons and empty states must use sentence case.
- Conflict-resolution sheet actions must use sentence case.
- Command-result titles produced by in-window actions should use sentence case.
- macOS command menus and context-menu commands must keep title case.

## Acceptance

- Diff empty states and hunk action controls no longer use menu-style title
  casing.
- Conflict-resolution actions read as `Accept ours`, `Accept theirs`, and
  `Mark resolved`.
- `swift test`, the app verification script, and whitespace checks pass.
