# Spec 0174: Force Push with Lease

## Objective

Support the safe force-push workflow users need after amend or rebase while
keeping destructive remote updates behind explicit confirmation.

## Requirements

- Bonsai exposes `Force Push with Lease...` for the current branch from the
  Repository command menu.
- Bonsai exposes the same action from the toolbar actions menu.
- The action is enabled only when the current branch has a usable upstream.
- Confirming the action runs `git push --force-with-lease <remote>
  <local>:<upstream-branch>`.
- The confirmation sheet names the local branch and upstream target.
- Normal push and publish behavior remain unchanged.

## Acceptance

- Integration coverage proves a rewritten current branch can update its
  upstream with `--force-with-lease`.
- Store coverage proves the force-push request is unavailable without a usable
  upstream.
- `swift test`, the app verifier, and whitespace checks pass.
