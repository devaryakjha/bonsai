# Spec 0188: Diff Empty State Copy

## Intent

The diff detail surface should stay quiet when nothing is selected. Empty states
should state the current condition instead of giving visible instructions.

## Requirements

- Use the same factual title for the diff header and empty diff body.
- Do not show extra instructional copy such as choosing or selecting a file.
- Keep the empty-state icon so the region remains identifiable without adding
  text.
- Keep the copy sentence-case and aligned with `Documentation/InterfaceStandards.md`.

## Acceptance

- Unit coverage locks the diff empty-state title.
- The detail header and body use the shared copy policy.
- Validation gates pass.
