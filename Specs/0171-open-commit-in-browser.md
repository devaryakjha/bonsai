# Spec 0171: Open Commit in Browser

## Objective

Let users inspect commits on GitHub from the history context menu without adding
visible metadata to commit rows.

## Requirements

- Commit context menus expose `Open in Browser` when the repository has a
  configured GitHub remote.
- Commit context menus expose `Copy Web URL` for the same browser target.
- If `origin` is a GitHub remote, Bonsai uses it for commit URLs; otherwise it
  falls back to the first configured GitHub remote.
- The feature reuses Bonsai's existing GitHub remote URL parser.
- Existing checkout, revision, branch, tag, and copy commit actions remain
  available.

## Acceptance

- Unit coverage proves GitHub commit web URLs include the full commit hash.
- Store coverage proves commit browser URLs prefer `origin` and fall back to
  another GitHub remote.
- `swift test`, the app verifier, and whitespace checks pass.
