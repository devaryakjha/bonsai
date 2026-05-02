# Spec 0041: In-progress Git Operations

## Objective

Surface in-progress merge, rebase, cherry-pick, and revert operations so users
can recover or continue from interrupted Git workflows without dropping to the
terminal.

## Requirements

- Detect in-progress merge, rebase, cherry-pick, and revert state from Git's own
  repository metadata.
- Expose continue, abort, and skip actions from Bonsai's primary Actions menu
  and macOS Git command menu.
- Disable skip for merge operations because Git merge has no skip action.
- Show active operation state in the sidebar with compact controls.
- Use Git's native `--continue`, `--abort`, and `--skip` commands for operation
  control.

## Acceptance

- Integration tests prove merge operation detection and abort against a real
  conflicted merge.
- Integration tests prove cherry-pick operation detection and skip against a
  real conflicted cherry-pick.
- `swift test` and the app verification script pass.
