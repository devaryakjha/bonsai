# Spec 0073: Push Readiness

## Objective

Keep push and publish actions honest by disabling them when Bonsai lacks a
branch or remote target.

## Requirements

- Push must require a checked-out local branch.
- Publishing an untracked branch must require at least one configured remote.
- Branches with usable upstream tracking must keep the existing `Push` behavior.
- Disabled push affordances must expose a short reason through help text.

## Acceptance

- Toolbar and app-menu push actions are disabled when push cannot succeed.
- Attempting push through the store without a remote target sets a clear error
  instead of invoking Git.
- Publishing a no-upstream branch with a remote remains available.
- `swift test`, the app verification script, and whitespace checks pass.
