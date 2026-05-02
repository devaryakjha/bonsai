# Spec 0072: Pull Readiness

## Objective

Prevent avoidable pull failures by only enabling pull when the current branch has
usable upstream tracking.

## Requirements

- Pull must require a checked-out local branch.
- Pull must require an upstream branch.
- Pull must not run when Git reports the upstream as gone.
- Disabled pull affordances must expose a short reason through help text.

## Acceptance

- Toolbar and app-menu pull actions are disabled when pull cannot succeed.
- Attempting pull through the store without upstream tracking sets a clear
  error instead of invoking Git.
- Existing fetch and push behavior remains unchanged.
- `swift test`, the app verification script, and whitespace checks pass.
