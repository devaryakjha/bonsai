# Spec 0232: Bounded Diff Find Count

## Intent

Keep the diff find control responsive on large patches by counting visible
matches only up to a practical UI cap instead of materializing and scanning a
full joined diff document for every label refresh.

## Requirements

- Empty or whitespace-only find queries still skip all visible diff evaluation.
- Unified find counts visible patch lines directly and excludes hidden patch
  metadata from the count.
- Split find counts old and new displayed line content directly and never counts
  line numbers.
- Match labels cap at the configured find-count limit with a compact `999+
  matches` style label.
- Search highlighting and raw diff rendering remain unchanged.

## Acceptance

- Unit coverage proves capped labels, empty-query laziness, unified metadata
  exclusion, and split/unified bounded counting.
- SwiftPM tests, app verifier, and whitespace checks pass.
