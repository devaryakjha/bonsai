# Spec 0214: Diff Find Lazy Match Count

## Intent

Keep the rich diff toolbar responsive by avoiding searchable-text materialization
until the user has entered a real find query.

## Requirements

- Empty or whitespace-only find queries do not build unified or split searchable
  diff text.
- Non-empty find queries keep the existing match-count labels.
- Unified and split find behavior remains unchanged once a query exists.
- Keep raw diff text and rendered diff content unchanged.

## Acceptance

- Unit coverage proves empty queries do not evaluate the visible-text provider.
- Unit coverage proves non-empty queries still count matches and return labels.
- SwiftPM tests, app verifier, and whitespace checks pass.
