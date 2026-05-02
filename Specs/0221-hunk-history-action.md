# Spec 0221: Hunk History Action

## Objective

Expose history for an entire diff hunk from the diff action strip, matching
Fork's hunk-history workflow without adding more always-visible controls.

## Requirements

- Derive a current-file line range from each parsed hunk header.
- Reuse the existing line-history sheet and `git log -L` path.
- Keep hunk and line history behind one compact `History` menu.
- Keep line-history entries available for precise changed-line inspection.
- Ignore hunks whose range cannot be parsed.

## Acceptance

- Unit coverage proves hunk range derivation for normal, single-line, and
  deleted hunks.
- The diff action strip exposes hunk history and line history from the same
  opt-in menu.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
