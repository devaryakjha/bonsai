# Spec 0203: Split Diff Placeholders

## Intent

Split diff mode should make one-sided changes read as intentional side-by-side
rows. A missing counterpart line should not look like an unfinished blank pane.

## Requirements

- Render one-sided split rows with a quiet `No line` placeholder on the missing
  side.
- Keep placeholder rows visually subordinate to actual added and deleted lines.
- Keep placeholder width bounded so long counterpart lines do not create huge
  blank runs.
- Do not include placeholder text in diff search highlighting.
- Keep the underlying parsed diff text unchanged for patch and search source
  behavior.

## Acceptance

- Render policy tests cover the placeholder text and width bounds.
- Existing split diff parser tests continue to prove one-sided rows are parsed
  as empty counterpart lines.
- SwiftPM tests and the app verifier pass.
