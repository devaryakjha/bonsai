# Spec 0238: Commit Context Menu Grouping

## Intent

Keep history commit context menus scannable as parity actions grow. The menu
should preserve Fork-style command reachability while grouping actions by job
instead of presenting one long flat list.

## Requirements

- Commit row context menus group revision commands under `Revision`.
- Commit row context menus group branch and tag creation under `Create`.
- Commit row context menus group browser actions under `Hosting` when a hosting
  URL is available.
- Commit row context menus group hash, subject, author, and patch copying under
  `Copy`.
- Existing checkout, revision, create, browser, web URL, and patch copy actions
  remain available.
- Menu labels remain short, professional, and non-wrapping.

## Acceptance

- Unit coverage pins commit context menu group labels.
- `swift test`, the app verifier, and whitespace checks pass.
