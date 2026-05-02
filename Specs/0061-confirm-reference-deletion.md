# Spec 0061: Confirm Reference Deletion

## Objective

Prevent accidental branch and tag deletion from sidebar context menus.

## Requirements

- Local branch, remote branch, and tag deletion must open a confirmation sheet
  before running Git.
- The sheet must clearly name the reference and explain the irreversible side
  effect in short professional copy.
- Current branch deletion must remain unavailable.
- Confirmation must keep the existing Git command behavior and refresh flow.

## Acceptance

- Context-menu delete actions no longer run immediately.
- The destructive confirmation button is the only path that calls the delete
  mutation.
- Delete request copy is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
