# Spec 0057: Separated Sidebar Disclosures

## Objective

Make repository infrastructure items readable at the sidebar level by replacing
the combined advanced disclosure with separate Worktrees, Remotes, and
Submodules disclosures.

## Requirements

- Worktrees, remotes, and submodules must each have their own disclosure row.
- Disclosure labels must include counts so users can understand each group
  before expanding it.
- Existing actions must remain reachable in the same relevant group.
- The Worktrees and Remotes groups must remain available when empty because
  they contain create/add actions.
- Submodules should appear only when the repository has submodules.

## Acceptance

- The sidebar no longer has one mixed infrastructure disclosure.
- Opening Worktrees does not visually mix remotes or submodules into the same
  stack.
- `swift test`, the app verification script, and whitespace checks pass.
