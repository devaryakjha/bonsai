# Spec 0124: Native History Stash Selection

## Objective

Make stash rows in the history list use the same native macOS selection
mechanics as commit rows.

## Requirements

- Commits and stashes share one `List(selection:)` binding.
- Selecting a stash still clears the selected commit and loads stash files.
- Selecting a commit still clears the selected stash.
- Stash rows no longer draw a custom rounded selected background.
- Existing stash context actions remain unchanged.

## Acceptance

- Stashes and commits select through the same list selection path.
- Spec 0022 stash inspection behavior remains intact.
- The app verification script, `swift test`, and whitespace checks pass.
