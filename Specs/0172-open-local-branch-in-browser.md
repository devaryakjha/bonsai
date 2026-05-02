# Spec 0172: Open Local Branch in Browser

## Objective

Let users inspect a local branch's upstream GitHub branch from the sidebar
context menu without adding visible metadata to branch rows.

## Requirements

- Local branch context menus expose `Open in Browser` when the branch tracks a
  configured GitHub remote branch.
- Local branch context menus expose `Copy Web URL` for the same browser target.
- Branches without an upstream do not expose browser actions.
- Branches whose upstream remote is not a configured GitHub remote do not expose
  browser actions.
- The feature reuses Bonsai's existing upstream parsing and GitHub remote URL
  parser.
- Existing checkout, create branch, create tag, rename, merge, rebase, pull,
  push, upstream, copy, and delete branch actions remain available.

## Acceptance

- Store coverage proves local branch browser URLs use the configured upstream
  remote and upstream branch name.
- Store coverage proves local branches without a GitHub upstream do not expose a
  browser URL.
- `swift test`, the app verifier, and whitespace checks pass.
