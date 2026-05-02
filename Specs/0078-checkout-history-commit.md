# Spec 0078: Checkout History Commit

## Objective

Let users checkout a commit directly from the history row context menu instead
of requiring the toolbar action.

## Requirements

- Commit history context menus must expose `Checkout`.
- The action must select the clicked commit before running checkout.
- Checkout must use the existing `RepositoryStore`/`GitClient` path.
- Existing toolbar checkout behavior must remain unchanged.

## Acceptance

- History row checkout is reachable beside other revision actions.
- Store-level integration coverage proves checking out a focused commit updates
  `HEAD`.
- `swift test`, the app verification script, and whitespace checks pass.
