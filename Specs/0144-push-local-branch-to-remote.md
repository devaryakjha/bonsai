# Spec 0144: Push Local Branch To Remote

## Objective

Let users publish any local branch from the sidebar instead of first checking it
out just to push it.

## Requirements

- Local branch context menus expose a `Push to Remote` submenu when at least one
  remote can be pushed to.
- The submenu lists configured remotes by name.
- Selecting a remote runs `git push -u <remote> <branch>`.
- The action routes through `RepositoryStore` and `GitClient`.
- Existing checkout, create branch, create tag, rename, upstream, copy, and
  delete actions remain unchanged.

## Acceptance

- Integration coverage proves a non-current local branch can be pushed to a bare
  remote.
- Pushing the branch records upstream tracking for future normal pushes.
