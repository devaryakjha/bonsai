# Spec 0062: Confirm Stash Drop

## Objective

Prevent accidental stash deletion from history and toolbar menus.

## Requirements

- Dropping a stash must open a confirmation sheet before running Git.
- The sheet must name the stash index and show the stash message.
- Both the stash row context menu and toolbar stash menu must use the same
  confirmation path.
- The existing apply and pop actions must keep their current behavior.

## Acceptance

- `Drop` menu actions no longer call the stash mutation directly.
- The destructive confirmation button is the only path that calls `stash drop`.
- Drop request copy is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
