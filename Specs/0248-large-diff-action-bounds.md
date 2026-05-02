# Spec 0248: Large Diff Action Bounds

## Intent

Keep rich diff inspection responsive on large patches. Bonsai should preserve
the full patch text, split rendering, search, and hunk actions while avoiding
presentation-only line-action models that become noisy and expensive at scale.

## Requirements

- Keep unified and split diff parsing available for large patches.
- Keep hunk-level actions available for large patches.
- Skip per-line stage, unstage, discard, and line-history menu entries when the
  diff exceeds the large-diff action threshold.
- Keep raw patch text unchanged for copy and Git apply operations.
- Avoid allocating a whole intermediate `[String]` line array inside core diff
  parsers.

## Acceptance

- Unit coverage proves the policy threshold.
- Store coverage proves large diffs retain hunks and split output while line
  actions are skipped.
- `swift test`, the app verifier, and whitespace checks pass.
