# Spec 0103: Compact Recent Message Menu

## Objective

Keep the recent commit-message menu compact when stored messages are long or
multi-line.

## Requirements

- Recent message menu items show a compact single-line preview.
- Selecting a recent message still restores the full stored commit message.
- Multi-line messages preview only their first non-empty line.
- Long preview text is truncated with a clear suffix.
- Preview formatting is covered by unit tests.

## Acceptance

- Long or multi-line recent messages cannot create oversized visible menu items.
- The stored commit message value remains unchanged when reused.
- `swift test`, the app verification script, and whitespace checks pass.
