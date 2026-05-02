# Commit Tree Browser Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Add Fork-style browsing of the repository file tree at the selected commit.
Users should be able to inspect a commit's full tree, not only the files changed
by that commit.

## Requirements

- Load one directory level from the selected commit using Git as the source of
  truth.
- Parse `git ls-tree -z` output so paths with spaces remain stable.
- Show folders and files in the history lower panel.
- Let users enter folders, navigate back up, and select files.
- Selecting a file shows the blob content in the detail pane.
- Changing commits resets the tree browser to the repository root.

## Acceptance Checks

- Parser tests cover tree entry parsing.
- Integration tests cover nested commit tree browsing and blob retrieval.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
