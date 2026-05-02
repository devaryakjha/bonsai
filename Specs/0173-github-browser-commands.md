# Spec 0173: GitHub Browser Commands

## Objective

Make GitHub browser targets reachable from standard macOS command surfaces
without adding visible metadata or controls to rows.

## Requirements

- The `Git > GitHub` command menu exposes `Open Current Branch in Browser` when
  the current local branch tracks a configured GitHub remote branch.
- The `Git > GitHub` command menu exposes `Copy Current Branch Web URL` for the
  same current-branch target.
- The `Git > GitHub` command menu exposes `Open Selected Commit in Browser` when
  a selected commit can be resolved against a configured GitHub remote.
- The `Git > GitHub` command menu exposes `Copy Selected Commit Web URL` for the
  same selected-commit target.
- The toolbar `Actions > Tools > GitHub` menu exposes the same browser and copy
  commands.
- Commands are disabled instead of hidden when their selected target is not
  available.
- Existing GitHub notification and repository commands remain grouped in the
  GitHub submenu.

## Acceptance

- Store coverage proves current-branch and selected-commit GitHub command URLs
  resolve from existing branch and commit URL helpers.
- `swift test`, the app verifier, and whitespace checks pass.
