# Spec 0184: Remote Pseudo-Ref Actions

## Intent

Remote pseudo refs such as `origin/HEAD` are useful context, but they are not
concrete remote branches. Bonsai should avoid offering branch-target actions
that imply a real remote branch name.

## Requirements

- Model whether a remote ref resolves to a concrete remote branch.
- Hide checkout, fetch, upstream, merge, rebase, and delete actions for remote
  pseudo refs.
- Keep copy and browser actions available when their data exists.
- Guard programmatic checkout of remote pseudo refs.

## Acceptance

- Unit coverage distinguishes concrete remote branches from pseudo refs.
- Existing real remote branch actions remain available.
- Validation gates pass.
