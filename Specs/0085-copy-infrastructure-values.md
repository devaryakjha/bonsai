# Spec 0085: Copy Infrastructure Values

## Objective

Keep infrastructure sidebar rows calm while making hidden paths, URLs, and
object identifiers easy to copy from context menus.

## Requirements

- Worktree rows expose Copy Path from their context menu.
- Remote rows expose copy actions for fetch and push URLs when present.
- Submodule rows expose Copy Path from their context menu.
- Git LFS file rows expose Copy Path and Copy Object ID from their context menu.
- Existing open, fetch, update, lock, unlock, edit, and remove actions must keep
  their current behavior.
- Hidden metadata must stay hidden from the default row layout.

## Acceptance

- Copy actions use the shared pasteboard helper.
- Remote copy actions are only shown for configured URLs.
- `swift test`, the app verification script, and whitespace checks pass.
