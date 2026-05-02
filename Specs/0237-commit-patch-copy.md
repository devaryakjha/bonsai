# Spec 0237: Commit Patch Copy

## Intent

Let users copy a complete commit patch directly from history. Stash rows already
support patch copying, and commit rows should offer the same Fork-style
inspection action without requiring Terminal.

## Requirements

- Commit row context menus expose `Copy Patch`.
- Patch generation lives behind `GitClient`, not inline view command strings.
- Copied patches honor the active diff algorithm and whitespace mode.
- Empty patch output surfaces a factual error instead of copying nothing.
- Existing revision, browser, and copy-value actions remain unchanged.

## Acceptance

- Command argument coverage proves complete commit patch generation.
- Integration coverage proves the Git command returns a full commit patch.
- `swift test`, the app verifier, and whitespace checks pass.
