# Spec 0090: Revision Command Client Boundary

## Objective

Keep v0 revision actions behind the Git client boundary instead of letting the
store assemble raw Git commands.

## Requirements

- `GitClient` exposes a typed method for cherry-pick, revert, merge, and rebase
  revision commands.
- `RepositoryStore` routes revision actions through that method.
- Existing history and toolbar action reachability remains unchanged.
- Integration coverage exercises the typed Git client path against real Git
  commands.

## Acceptance

- The store no longer calls `runRaw` for typed revision actions.
- Merge and cherry-pick conflict detection still work through the typed client
  method.
- `swift test`, the app verification script, and whitespace checks pass.
