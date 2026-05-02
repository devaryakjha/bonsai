# Branch Tracking Counts Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Show ahead/behind branch tracking state in the sidebar so users can tell which
local branches need pushing or pulling without opening a terminal.

## Requirements

- Load upstream tracking state from Git refs.
- Parse `ahead`, `behind`, combined ahead/behind, and gone upstream states.
- Show compact ahead/behind badges beside local branches.
- Keep existing branch checkout/delete behavior unchanged.

## Acceptance Checks

- Parser tests cover ahead, behind, combined, and gone tracking states.
- Integration tests cover a local branch ahead of its upstream.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
