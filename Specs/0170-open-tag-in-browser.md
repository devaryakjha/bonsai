# Spec 0170: Open Tag in Browser

## Objective

Let users inspect GitHub tags in the browser from the sidebar without adding
visible metadata to tag rows.

## Requirements

- Tag context menus expose `Open in Browser` when the repository has a
  configured GitHub remote.
- Tag context menus expose `Copy Web URL` for the same browser target.
- If `origin` is a GitHub remote, Bonsai uses it for tag URLs; otherwise it
  falls back to the first configured GitHub remote.
- The feature reuses Bonsai's existing GitHub remote URL parser.
- Existing checkout, create branch, rename, merge, rebase, push, copy, and
  delete tag actions remain available.

## Acceptance

- Unit coverage proves GitHub tag web URLs preserve tag path separators and
  percent-encode spaces.
- Store coverage proves tag browser URLs prefer `origin` and fall back to
  another GitHub remote.
- `swift test`, the app verifier, and whitespace checks pass.
