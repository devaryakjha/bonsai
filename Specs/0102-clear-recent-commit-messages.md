# Spec 0102: Clear Recent Commit Messages

## Objective

Let users clear stale commit-message history without adding persistent composer
controls.

## Requirements

- The recent messages menu exposes Clear Recent Messages when message history
  exists.
- Clearing recent messages removes only Bonsai's stored commit-message history.
- Clearing recent messages does not change the current commit message draft.
- Recent commit-message management routes through `RepositoryStore`.
- The composer remains visually unchanged when there are no recent messages.

## Acceptance

- Users can clear all recent commit messages from the composer menu.
- The current commit draft remains intact after clearing message history.
- Store behavior is covered by tests.
- `swift test`, the app verification script, and whitespace checks pass.
