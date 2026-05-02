# Stashes In History Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Move stashes into the history inspection flow so Bonsai matches Fork's ability
to see stashes directly in the commit list, not only from a toolbar menu.

## Requirements

- Show stashes above commits in the history list.
- Selecting a stash loads its changed files.
- Selecting a stash file shows a Git-backed patch diff.
- Existing stash actions, apply, pop, and drop, remain available from the stash
  row context menu.
- Changing to a normal commit clears the active stash selection.

## Acceptance Checks

- Integration tests cover stash changed-file and diff retrieval.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
