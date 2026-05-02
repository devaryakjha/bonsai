# Spec 0162: Reference Operation Naming

## Objective

Keep the merge and rebase operation layer accurate now that those actions
support local branches, remote-tracking branches, and tags.

## Requirements

- Store and client method names refer to references, not only branches.
- Existing merge and rebase behavior remains unchanged.
- Sidebar context menus keep the same visible copy.

## Acceptance

- Branch, remote branch, and tag merge/rebase integration tests continue to
  pass.
- `swift test`, the app verifier, and whitespace checks pass.
