# Spec 0154: Pull Local Branch

## Objective

Let users pull a selected local branch with an upstream from the branch context
menu, matching the direct branch operations expected in a desktop Git client.

## Requirements

- Local branch context menus expose `Pull` when the branch has an upstream.
- Branches with gone upstreams keep the action unavailable.
- Pulling the current branch uses the existing fast-forward-only pull behavior.
- Pulling a non-current local branch must not checkout that branch.
- Pulling a non-current branch fetches its upstream into both the matching
  remote-tracking ref and the local branch ref, using Git's normal
  fast-forward protection.
- Existing checkout, create, rename, push, upstream, copy, and delete actions
  remain unchanged.

## Acceptance

- A non-current local branch behind its upstream can be fast-forwarded from the
  context-menu action while the current branch remains unchanged.
- Branch upstream parsing supports remote branch names containing slashes.
- `swift test`, the app verification script, and whitespace checks pass.
