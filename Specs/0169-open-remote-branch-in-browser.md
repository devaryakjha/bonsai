# Spec 0169: Open Remote Branch in Browser

## Objective

Let users inspect GitHub remote branches in the browser from the sidebar without
adding visible metadata to reference rows.

## Requirements

- Remote branch context menus expose `Open in Browser` when the branch belongs
  to a configured GitHub remote.
- Remote branch context menus expose `Copy Web URL` for the same browser target.
- Symbolic remote `HEAD` rows do not expose browser branch actions.
- The feature reuses Bonsai's existing remote and GitHub target parsing.
- Existing checkout, fetch, branch, tag, upstream, merge, rebase, copy, and
  delete remote-branch actions remain available.

## Acceptance

- Unit coverage proves GitHub branch web URLs preserve branch path separators
  and percent-encode spaces.
- Unit coverage proves a GitHub remote can derive a branch web URL.
- `swift test`, the app verifier, and whitespace checks pass.
