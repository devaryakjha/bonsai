# Hunk Staging Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Support Fork-style partial staging from the diff viewer. v0 starts with hunk
staging and unstaging, with line-level staging reserved for the next refinement.

## Requirements

- Working-tree diffs are parsed into individual hunks.
- Staged diffs are parsed into individual hunks.
- A user can stage one unstaged hunk without staging the entire file.
- A user can unstage one staged hunk without unstaging the entire file.
- Patch application runs through `GitClient`; views never shell out directly.
- Failed patch application reports Git output in the command result area.

## Acceptance Checks

- Parser tests cover multi-hunk diffs and patch reconstruction.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
