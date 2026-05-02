# Spec 0099: Auto Refresh Preference

## Objective

Make the Settings toggle for refresh behavior control repository refreshes after
Git mutations.

## Requirements

- `Refresh after Git operations` remains enabled by default.
- When enabled, successful mutating Git operations refresh the visible
  repository state.
- When disabled, successful mutating Git operations leave the current snapshot
  untouched until the user refreshes manually.
- Failed operations keep surfacing their command result and error message.
- The preference is owned by the store boundary, not individual views.

## Acceptance

- Store-level mutation behavior is covered by integration tests.
- Existing manual refresh actions still call `refreshAll()`.
- `swift test`, the app verification script, and whitespace checks pass.
