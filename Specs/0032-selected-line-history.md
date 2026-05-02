# Selected Line History Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Add selected-code history from the diff surface. Users should be able to inspect
the commit history for a changed line range directly from the diff action strip,
matching modern Fork-style code inspection workflows.

## Requirements

- Derive a line range from each parsed diff line change.
- Load line history with `git log -L <start>,<end>:<path>` and structured commit
  fields.
- Present the resulting commit timeline in a native sheet.
- Allow jumping from a line-history entry back to the main selected commit.
- Keep failures user-visible when Git cannot trace the selected range.

## Acceptance Checks

- Integration tests prove line history returns commits for a real repository.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
