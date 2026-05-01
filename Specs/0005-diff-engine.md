# Diff Engine Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Make Bonsai's diff viewer a durable core surface rather than a disposable
prototype. Bonsai should rely on Git's mature diff engine for correctness while
using native macOS text rendering for large-file performance.

## Algorithm Policy

- Default algorithm: `histogram`.
- User-selectable algorithms: `histogram`, `patience`, `myers`, `minimal`.
- Bonsai does not hand-roll the core diff algorithm in v0.
- Bonsai passes explicit diff options to Git so behavior is stable across
  repositories and user config.
- Bonsai disables external diff hooks and color escape output for its internal
  renderer so the parsed patch text is deterministic.

Git's official diff algorithm option documents `myers`, `minimal`, `patience`,
and `histogram`. `histogram` extends patience-style matching to support
low-occurrence common elements, which is a strong default for readable code
review diffs.

## Rendering Policy

- Use AppKit text rendering for full diff text.
- Keep hunk-level action controls in SwiftUI, but do not render every diff line
  as an independent SwiftUI view for the normal path.
- Preserve text selection.
- Highlight additions, deletions, and hunk headers.
- Keep unified patch text available so hunk staging can apply exact patches.
- Support unified and split side-by-side viewing modes.

## Acceptance Checks

- All Git diff calls use explicit algorithm options.
- Settings expose the diff algorithm.
- The diff view uses an AppKit-backed renderer.
- The diff view can switch between unified and split modes.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
