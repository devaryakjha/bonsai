# Image Before/After Diff Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Upgrade image diffs from a single working-tree preview to a real before/after
comparison using Git objects as the source of truth.

## Requirements

- Working-tree image changes show old and new image states when available.
- Staged image changes use the index image as the new state.
- Commit image changes show parent and commit image states when available.
- Binary-safe Git output is used for image blobs.
- Missing sides, such as added or deleted images, render as explicit placeholders.

## Acceptance Checks

- Binary process output is supported in `ProcessRunner`.
- Image blob retrieval lives in `GitClient`.
- Image snapshot retrieval is covered by integration tests.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
