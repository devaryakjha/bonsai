# Spec 0046: Working Tree Composer Polish

## Objective

Reduce working-tree visual load while preserving fast access to common Git
actions and full feature parity for file operations and commit options.

## Requirements

- Stage and unstage must remain direct row actions.
- Conflict resolution must remain visible for conflicted files.
- Secondary file actions, including destructive discard, must be opt-in from a
  row action menu and the existing context menu.
- Commit amend and signing controls must be available without being always
  visible toggles.
- The commit message editor must communicate its purpose without relying on a
  wrapping label.
- Active optional commit settings must remain discoverable before committing.

## Acceptance

- Working-tree rows show fewer default controls while retaining every prior
  action path.
- The commit composer keeps the primary commit action visually dominant.
- Optional commit settings are explicit when selected and otherwise opt-in.
- `swift test`, the app verification script, and whitespace checks pass.
