# Spec 0143: Push Tag To Remote

## Objective

Complete the basic tag management loop by letting users push an existing local
tag to a configured remote without leaving Bonsai.

## Requirements

- Tag context menus expose a `Push to Remote` submenu when at least one remote
  can be pushed to.
- The submenu lists configured remotes by name.
- Selecting a remote runs `git push <remote> <tag>`.
- The action routes through `RepositoryStore` and `GitClient`.
- Existing tag checkout, branch creation, copy, and delete actions remain
  unchanged.

## Acceptance

- Integration coverage proves a local tag can be pushed to a bare remote.
- The action refreshes repository state and reports command output through the
  existing mutation path.
