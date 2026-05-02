# Spec 0087: Copy Stash Values

## Objective

Make stash rows and stash menus useful when users need to paste a stash
reference or message into another Git command, issue, or review thread.

## Requirements

- Stash history-row context menus expose copy actions for the stash reference
  and message.
- Toolbar stash submenus expose the same copy actions.
- Stash branch names are copyable when Git reports one.
- Existing apply, pop, branch, and drop actions must remain unchanged.
- Copy actions must use the shared pasteboard helper.

## Acceptance

- Copy stash reference uses the full stash index such as `stash@{0}`.
- Copy message uses the parsed stash message.
- `swift test`, the app verification script, and whitespace checks pass.
