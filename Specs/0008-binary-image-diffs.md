# Binary and Image Diff Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Handle binary and image changes deliberately in the diff surface. v0 should not
render binary diff output as if it were source code.

## Requirements

- Detect common image file extensions.
- Detect binary diff output from Git.
- Show a native image preview for working-tree image selections when possible.
- Show a clear binary placeholder with file path and diff status.
- Keep source-code diffs on the AppKit-backed text renderer.

## Acceptance Checks

- Image extension detection is unit-tested.
- Binary diff detection is unit-tested.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
