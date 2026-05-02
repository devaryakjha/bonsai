# Spec 0100: Clear Recent Repositories

## Objective

Let users clear stale recent repositories without closing the active repository
or adding persistent sidebar controls.

## Requirements

- The Repository command menu exposes Clear Recent Repositories.
- The action is disabled when the recents list is empty.
- Clearing recents removes only Bonsai's recent-repository list.
- Clearing recents does not delete files or close the active repository.
- Recents management routes through `RepositoryStore`.

## Acceptance

- Users can clear all recent repositories from the menu.
- The selected repository remains selected after clearing recents.
- Store behavior is covered by tests.
- `swift test`, the app verification script, and whitespace checks pass.
