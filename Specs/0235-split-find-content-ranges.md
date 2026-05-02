# Spec 0235: Split Find Content Ranges

## Intent

Keep split diff find behavior aligned with the visible match count by searching
source content only, not gutters or generated placeholders.

## Requirements

- Split diff search highlighting ignores line numbers and gutter separators.
- Split diff find navigation selects only source-content matches.
- Generated missing-side placeholder text does not become searchable.
- Existing split gutter rendering, inline changed-token highlights, and scroll
  synchronization remain unchanged.

## Acceptance

- Unit coverage proves rendered split search ranges find source text but ignore
  gutter line numbers.
- Unit coverage proves rendered split search ranges ignore missing-side
  placeholders.
- SwiftPM tests, app verifier, and whitespace checks pass.
