# Spec 0044: Diff Header Controls

## Objective

Make the diff header calmer and more resilient while keeping advanced diff
controls available.

## Requirements

- Keep the current diff title and metadata as the primary visual focus.
- Keep unified/split mode immediately available as a compact segmented control.
- Move diff algorithm selection into an opt-in options menu instead of showing
  every algorithm all the time.
- Preserve the active algorithm indication inside the options menu.
- Keep copy-patch one click away while avoiding a wide text button in the
  constrained header.

## Acceptance

- The diff header no longer renders the four-option algorithm segmented control.
- The diff options menu exposes all diff algorithms and marks the current one.
- Copy Patch remains available with hover and accessibility labels.
- `swift test` and the app verification script pass.
