# Spec 0151: Fetch Remote Branch

## Objective

Let users update a single remote-tracking branch from the remote branch context
menu without fetching every branch from the remote.

## Requirements

- Remote branch rows expose `Fetch Branch` from their context menu.
- Fetching a remote branch must update `refs/remotes/<remote>/<branch>` for the
  selected branch.
- Remote `HEAD` rows and non-remote refs must not be treated as fetchable
  remote branches.
- Successful fetches refresh repository state through the existing mutation
  pipeline and command result surface.
- Existing remote fetch, checkout, branch creation, upstream, copy, and delete
  actions remain unchanged.

## Acceptance

- Selecting `Fetch Branch` for `origin/main` fetches only `main` from `origin`
  into `refs/remotes/origin/main`.
- Invalid remote branch refs report a Git client error instead of constructing
  an ambiguous fetch command.
- `swift test`, the app verification script, and whitespace checks pass.
