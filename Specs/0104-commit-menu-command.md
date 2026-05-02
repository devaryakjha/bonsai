# Spec 0104: Commit Menu Command

## Objective

Expose the primary commit action through standard macOS command surfaces, not
only the working-tree composer button.

## Requirements

- The Git command menu exposes Commit when the composer is ready to create a
  normal commit.
- The same command reads Amend Commit when amend mode is active.
- The command uses the existing `RepositoryStore.commit()` path.
- The command is disabled when no repository is selected or the commit composer
  is not ready.
- The command has a keyboard shortcut for desktop workflow parity.

## Acceptance

- Users can commit from the Git menu.
- Users can use the same shortcut for normal and amend commits.
- Existing commit validation and state-preservation behavior remain unchanged.
- `swift test`, the app verification script, and whitespace checks pass.
