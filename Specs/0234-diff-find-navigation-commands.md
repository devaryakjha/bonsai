# Spec 0234: Diff Find Navigation Commands

## Intent

Align diff find navigation with standard macOS keyboard behavior so users can
move through matches without leaving the keyboard.

## Requirements

- `Command-F` continues to open the diff find field.
- `Command-G` moves to the next diff find match.
- `Command-Shift-G` moves to the previous diff find match.
- Find navigation commands are disabled unless the diff find field is open and
  the current query has at least one visible match.
- Command routing stays view-owned through focused values and does not introduce
  global references to diff views or text views.

## Acceptance

- The Edit command group exposes find, find-next, and find-previous actions with
  standard shortcuts.
- The same focused navigation path drives menu shortcuts and visible header
  controls.
- SwiftPM tests, app verifier, and whitespace checks pass.
