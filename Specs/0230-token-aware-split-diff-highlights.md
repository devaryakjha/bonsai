# Spec 0230: Token-Aware Split Diff Highlights

## Objective

Make split diffs easier to scan by highlighting precise changed tokens in
replacement lines instead of one broad changed span.

## Requirements

- Keep split diff rendering bounded for large files and long lines.
- Preserve the existing prefix/suffix fallback for oversized comparisons.
- Highlight multiple changed regions when a line has separate token-level edits.
- Keep search highlights and one-sided placeholder rows unchanged.
- Keep the implementation local to the existing diff render pipeline.

## Acceptance

- Unit coverage proves separate changed tokens produce separate ranges.
- Unit coverage proves oversized token comparisons fall back to one broad range.
- Existing split placeholder, search, and render policy tests keep passing.
- `swift test`, the app verifier, and whitespace checks pass.
