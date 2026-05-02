# Stash Untracked Files Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Extend stash creation so users can include untracked files without leaving
Bonsai. Fork-style stash workflows commonly offer this as an explicit variant
because it changes what disappears from the working tree.

## Requirements

- Keep the existing Create Stash action for tracked changes.
- Add a Create Stash Including Untracked action.
- Apply the same optional message sheet to both stash variants.
- Execute the untracked variant with `git stash push --include-untracked`.
- Refresh status and stashes after creating either variant.

## Acceptance Checks

- Integration tests cover stashing an untracked file.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
