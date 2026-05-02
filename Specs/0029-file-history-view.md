# File History View Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Replace raw per-file history output with a native structured view. Bonsai should
let users inspect the commit timeline for a selected file, including renames,
without parsing terminal text.

## Requirements

- Load file history with `git log --follow --name-status` and a
  machine-readable pretty format.
- Parse entries into commit hash, short hash, author, author email, author date,
  subject, and per-entry file changes.
- Present history from the selected working-tree or revision file in a dense
  native sheet.
- Show rename/copy/modify status and old paths when Git reports them.
- Keep the existing raw `fileHistory` command available for diagnostics.

## Acceptance Checks

- Parser tests cover multiple file-history entries and a rename record.
- Integration tests prove `GitClient` returns structured file history for a real
  repository.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
