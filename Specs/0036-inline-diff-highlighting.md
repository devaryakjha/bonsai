# Inline Diff Highlighting Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Improve diff readability by highlighting the changed segment inside replacement
lines. Whole-line coloring is useful, but users also need to see exactly which
word or token changed without scanning the entire line.

## Requirements

- Detect changed ranges for adjacent removed/added line pairs.
- Highlight changed ranges inside unified diff replacement pairs.
- Highlight changed ranges inside split diff replacement pairs.
- Keep the renderer AppKit-backed, selectable, horizontally scrollable, and
  non-wrapping.
- Keep metadata, hunk, binary, and image diff behavior unchanged.

## Acceptance Checks

- Unit tests cover inline changed range detection.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
