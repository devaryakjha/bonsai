# Spec 0256: Large Repository Performance Pass

## Intent

Close the v0 performance gate for history loading and rich diff parsing with a
repeatable smoke test. Bonsai should keep using Git for diff correctness while
avoiding avoidable parser allocations in its native renderer path.

## Requirements

- Keep Git as the source of truth for diff generation and history data.
- Avoid whole intermediate line arrays in hot parser paths for status, history,
  unified hunks, and split diffs.
- Preserve hunk parsing and split diff output for large patches.
- Preserve the large-diff policy that skips per-line mutation actions above the
  line-action threshold.
- Add an opt-in performance smoke that measures 300-commit history loading, a
  24,000-line rich diff parse, and a working-tree image diff snapshot/metadata
  path.
- Keep the smoke out of normal full-suite cost unless explicitly requested.

## Acceptance

- Parser tests continue to pass after the no-line-array parser refactor.
- `script/perf_large_repo.sh` runs the opt-in performance smoke.
- The smoke prints history and diff parse timing evidence.
- `Specs/0242-v0-parity-evidence.md` removes the open large-repository
  performance gate.
- `swift test`, `script/perf_large_repo.sh`, the app verifier, release packaging
  verifier, and whitespace checks pass.

## Evidence

- 2026-05-03 local smoke on Apple Silicon:
  `history_commits=300 history_ms=35 diff_lines=24000 parse_ms=27 image_ms=36`.
