# Reflog Recovery Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Upgrade reflog from a raw text dump to a recovery workflow. Bonsai should let
users inspect reflog entries and recover a lost revision by checking it out or
resetting the current branch to it.

## Requirements

- Load reflog entries with stable machine-readable fields.
- Show reflog entries in a sheet with selector, short hash, subject, and date.
- Let users checkout a reflog entry.
- Let users reset to a reflog entry with the existing reset mode choices.
- Keep raw reflog unavailable from the primary UI; recovery actions should use
  parsed entries.

## Acceptance Checks

- Parser tests cover reflog entry parsing.
- Integration tests cover reflog entry retrieval after multiple commits.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
