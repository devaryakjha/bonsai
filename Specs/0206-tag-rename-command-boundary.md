# Spec 0206: Tag Rename Command Boundary

## Intent

Tag rename preserves annotated tag objects by moving refs with `update-ref`.
That command sequence should be explicit and tested like other v0 tag mutation
commands.

## Requirements

- Keep tag rename as a ref move: resolve the old tag object, create the new tag
  ref at that object, then delete the old tag ref.
- Keep old and new tag names as single arguments, even when they contain spaces.
- Preserve existing store behavior and annotated-tag integration coverage.

## Acceptance

- Command argument tests cover tag rename resolve, create, and delete steps.
- Existing annotated tag rename integration test continues to pass.
- SwiftPM tests, the app verifier, and whitespace checks pass.
