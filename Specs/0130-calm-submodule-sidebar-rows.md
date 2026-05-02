# Spec 0130: Calm Submodule Sidebar Rows

## Objective

Keep submodules inspectable without making every sidebar row carry commit-level
metadata by default.

## Requirements

- Submodule rows show the path and readable state only.
- The full commit hash remains available through hover help and a context-menu
  copy action.
- Changed and conflicted submodules use semantic icon color so state can be
  scanned without reading the full detail text.
- Existing open, update, and copy-path actions remain reachable.

## Acceptance

- Submodule commit hashes are no longer always visible in the sidebar.
- Submodule rows still expose path, state, and commit information.
- `swift test`, the app verification script, and whitespace checks pass.
