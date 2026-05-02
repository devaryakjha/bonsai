# Spec 0068: Commit Readiness

## Objective

Prevent avoidable failed commit attempts by making the commit composer reflect
whether Git has enough input to create a commit.

## Requirements

- A normal commit must require a non-empty commit message and at least one staged
  change.
- An amend commit may proceed with a non-empty message even when no new changes
  are staged.
- The primary commit button must stay disabled until the active commit mode can
  succeed.
- The disabled state must expose a short, professional reason through help text.

## Acceptance

- The store exposes commit readiness independent of view layout.
- Attempting a normal commit without staged changes sets a clear error instead
  of invoking Git.
- The composer keeps optional commit settings opt-in and the primary action
  visually dominant.
- `swift test`, the app verification script, and whitespace checks pass.
