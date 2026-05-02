# Spec 0094: Reveal Repository Action

## Objective

Expose the standard macOS action for locating the active repository folder in
Finder.

## Requirements

- The Repository command menu exposes Reveal in Finder when a repository is
  selected.
- The sidebar repository row exposes the same action from its context menu.
- The action routes through `RepositoryStore`.
- Repository URL resolution uses the shared repository file locator.

## Acceptance

- Users can reveal the active repository without selecting a specific file.
- Repository root URL resolution is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
