# Spec 0196: Remote Command Boundaries

## Intent

Remote management is a core v0 Git-client surface. Its Git command arguments
should be testable at the process boundary instead of being assembled only in
async methods.

## Requirements

- Route remote add, set-url, rename, remove, fetch, and prune through static
  argument builders.
- Route remote branch fetch through a static argument builder.
- Preserve remote names, URLs, and branch names as single arguments.
- Preserve fetch-prune behavior for whole-remote fetches.
- Reject pseudo remote refs such as `origin/HEAD` for branch fetches.

## Acceptance

- Command argument coverage proves remote add, set-url, rename, remove, fetch,
  and prune commands.
- Command argument coverage proves remote branch fetch refspec construction.
- Command argument coverage proves remote branch fetch rejects pseudo refs.
- SwiftPM tests and the app verifier pass.
