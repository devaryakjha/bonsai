# History Graph Lanes Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Replace the flat history list with a Git-backed commit graph lane column. Bonsai
does not need to invent graph topology in v0; Git already produces the canonical
ASCII graph for the selected history walk.

## Requirements

- Load history with `git log --graph` and machine-readable commit fields.
- Preserve graph lane text per commit while ignoring graph continuation rows.
- Render the lane column beside each commit subject.
- Keep existing commit selection, search, decorations, and context menus working.

## Acceptance Checks

- Parser tests cover graph-prefixed commits and skipped continuation rows.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
