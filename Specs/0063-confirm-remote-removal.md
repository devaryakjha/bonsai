# Spec 0063: Confirm Remote Removal

## Objective

Prevent accidental removal of configured Git remotes.

## Requirements

- Removing a remote from the sidebar must open a confirmation sheet before
  running Git.
- The sheet must name the remote and show its configured URL when available.
- The existing add and edit remote flows must keep their current behavior.
- The confirmation button must be marked destructive.

## Acceptance

- The remotes context-menu `Remove` action no longer calls the mutation
  directly.
- The destructive confirmation button is the only UI path that calls
  `git remote remove`.
- Remove request copy is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
