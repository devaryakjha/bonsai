# Spec 0092: Confirm Revision Commands

## Objective

Prevent accidental branch mutation from history and toolbar revision actions by
showing the selected commit before running the command.

## Requirements

- Cherry-pick, revert, merge, and rebase actions open a confirmation sheet
  before running Git.
- The sheet names the command, target short hash, and target subject.
- Confirming runs the existing typed `GitClient` revision command path.
- Canceling leaves repository state unchanged.
- Existing history-row and toolbar menu reachability remains unchanged.

## Acceptance

- History and toolbar revision actions no longer run immediately from menu
  selection.
- Model tests cover the confirmation copy for each revision command.
- `swift test`, the app verification script, and whitespace checks pass.
