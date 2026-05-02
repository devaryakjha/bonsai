# Spec 0089: Typed Revision Actions

## Objective

Make revision actions safer and more professional by replacing raw command
strings with a typed model for checkout-adjacent operations.

## Requirements

- Cherry-pick, revert, merge, and rebase revision actions must route through a
  typed value instead of ad hoc strings in views.
- Each typed action must own its Git subcommand and user-facing menu copy.
- Command result titles must use professional sentence-case copy such as
  `Cherry-pick abc1234`, not mechanically capitalized command strings.
- Existing history-row and toolbar reachability must remain unchanged.

## Acceptance

- Views no longer pass raw revision-command strings to the store.
- Unit tests cover the typed action titles and Git subcommands.
- `swift test`, the app verification script, and whitespace checks pass.
