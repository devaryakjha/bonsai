# Spec 0243: Fork Release Parity Refresh

## Intent

Refresh Bonsai's parity target against current public Fork Mac release notes,
not only the older homepage feature list. The refresh should capture new or
newly visible Fork surfaces as explicit Bonsai backlog items or verified
implementation evidence.

## Source Snapshot

- Fork homepage feature overview, refreshed 2026-05-03:
  https://www.fork.dev/
- Fork Mac release notes, refreshed 2026-05-03. Current page lists Fork 2.66 and
  includes recent Mac items such as Claude branch review, multiple source code
  directories, hunk history from the file tree, file history for selected code,
  worktree branch icons, external editor additions, conflict-resolved diffs,
  repository treemap, repository benchmark, and SVG/TGA image support:
  https://fork.dev/releasenotes

## Requirements

- Keep the v0 parity evidence matrix tied to the current Fork public pages.
- Treat release-note features as audit candidates even when they are not on the
  homepage feature matrix.
- Add missing image diff format detection for Fork's SVG and TGA image support.
- Keep image diff routing path-based and binary-safe through existing
  `GitClient` blob retrieval.
- Do not mark v0 complete from this refresh alone.

## Current Delta

| Fork release-note surface | Bonsai state |
| --- | --- |
| Multiple source code directories | Covered by configurable workspace source directories and workspace groups |
| Hunk history / selected-code history | Covered by hunk and line-history actions from diff controls |
| Worktree icon for branches checked out elsewhere | Covered by branch worktree indicators |
| SVG and TGA image diffs | Covered by this spec |
| External editor reveal/open-in additions | Covered by `Specs/0244-external-editor-open-in.md` |
| Claude branch review and generated commit messages | Needs dedicated provider/local-AI design before v0 completion |
| Conflict-resolved diffs after external merge tools | Covered by `Specs/0245-conflict-resolved-diff.md` |
| Repository benchmark | Covered by `Specs/0246-repository-benchmark.md` |
| Repository treemap | Needs dedicated analytics spec |

## Acceptance

- SVG and TGA paths are recognized as image diff candidates.
- `Specs/0242-v0-parity-evidence.md` records the latest release-note refresh
  and the remaining release-note gaps.
- `swift test`, the app verifier, and whitespace checks pass.
