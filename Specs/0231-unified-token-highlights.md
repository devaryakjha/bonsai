# Spec 0231: Unified Token Highlights

## Objective

Keep unified diff highlighting consistent with split diff highlighting by
rendering every bounded token-level changed range.

## Requirements

- Apply all inline changed ranges in unified diff rows, not only the first one.
- Reuse the existing bounded `DiffInlineHighlighter` policy.
- Preserve hidden patch metadata, search highlights, and large-diff safeguards.
- Keep the change local to unified diff rendering.

## Acceptance

- Existing token-aware highlighter tests cover multiple changed ranges.
- Existing diff search and render policy tests keep passing.
- `swift test`, the app verifier, and whitespace checks pass.
