# Spec 0200: Command Result Presentation

## Intent

Command feedback should confirm work without turning the detail pane into a
second log viewer. Long paths, refs, and process output must stay available
without wrapping compact status text.

## Requirements

- Command result titles stay on one line in the compact strip.
- Long titles truncate visually but remain available through hover help and
  accessibility labels.
- Command summaries stay on one line while full output remains available through
  disclosure.
- Empty successful mutations use the concise fallback `Completed`.
- Empty successful read-only commands use the concise fallback `No output`.
- Summary copy is centralized on `CommandResult` instead of duplicated in the
  view.

## Acceptance

- Unit coverage proves command result summary fallback and first-line behavior.
- The detail strip presents long titles and summaries without wrapping.
- SwiftPM tests and the app verifier pass.
