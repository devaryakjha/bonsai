# Spec 0165: LFS File Open Actions

## Objective

Make Git LFS file rows directly inspectable from the sidebar without adding
visible row metadata or secondary inline controls.

## Requirements

- LFS file context menus expose `Open`.
- LFS file context menus expose `Reveal in Finder`.
- Existing `Copy Path`, `Copy Object ID`, `Lock`, and `Unlock` actions remain
  available.
- LFS file URL resolution stays repository-relative and preserves spaces in
  paths.

## Acceptance

- Unit coverage proves LFS file URLs are resolved relative to the selected
  repository while preserving spaces in paths.
- `swift test`, the app verifier, and whitespace checks pass.
