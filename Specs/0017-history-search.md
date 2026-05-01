# History Search Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Add commit history filtering so users can quickly find commits by subject,
author, hash, or decoration.

## Requirements

- History view exposes a native search field.
- Filtering matches commit subject, author, short/full hash, and decorations.
- Clearing search restores the full commit list.
- Selecting a filtered commit still updates changed files and diff.

## Acceptance Checks

- Filtering logic is covered by unit tests.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
