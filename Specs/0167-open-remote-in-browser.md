# Spec 0167: Open Remote in Browser

## Objective

Let users jump from a configured GitHub remote to its repository page without
copying clone URLs by hand.

## Requirements

- Remote context menus expose `Open in Browser` when the remote resolves to a
  GitHub repository.
- Remote context menus expose `Copy Web URL` for the same resolved repository.
- The feature reuses Bonsai's existing GitHub remote URL parser.
- Non-GitHub remotes do not show misleading browser actions.
- Existing fetch, prune, copy clone URL, edit URL, and remove remote actions
  remain available.

## Acceptance

- Unit coverage proves GitHub repository targets expose the expected web URL.
- Unit coverage proves remotes expose the first derived GitHub web URL.
- `swift test`, the app verifier, and whitespace checks pass.
