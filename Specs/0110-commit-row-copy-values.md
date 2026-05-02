# Spec 0110: Commit Row Copy Values

## Objective

Make commit history rows useful for review and terminal workflows that need more
than the full commit hash.

## Requirements

- Commit row context menus expose copy actions for full hash, short hash,
  subject, author name, and author email.
- Copy actions use the shared pasteboard helper.
- Existing checkout, revision, reset, branch, and tag actions remain unchanged.
- Commit rows remain visually unchanged.

## Acceptance

- Users can copy commit identity and summary values from the history row context
  menu.
- Empty author email values do not produce a useless copy action.
- `swift test`, the app verification script, and whitespace checks pass.
