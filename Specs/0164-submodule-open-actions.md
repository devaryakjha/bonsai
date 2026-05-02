# Spec 0164: Submodule Open Actions

## Objective

Make submodule rows easier to inspect from the sidebar without adding visible
row metadata.

## Requirements

- Submodule context menus expose `Reveal in Finder`.
- Submodule context menus expose `Open in Terminal`.
- Submodule filesystem URL resolution uses a typed helper instead of rebuilding
  paths in the view.
- Existing `Open Submodule`, `Update Submodule`, `Copy Path`, and
  `Copy Commit Hash` actions remain available.

## Acceptance

- Unit coverage proves submodule directory URLs are resolved relative to the
  selected repository while preserving spaces in paths.
- `swift test`, the app verifier, and whitespace checks pass.
