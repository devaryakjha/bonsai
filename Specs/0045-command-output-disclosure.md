# Spec 0045: Command Output Disclosure

## Objective

Keep Git command output available without letting routine command results
permanently compete with the selected diff.

## Requirements

- Command output must appear as a compact status strip instead of an always-open
  block.
- Successful command output must be collapsed by default.
- Error output must be expanded by default.
- Users must be able to expand output for details and select/copy the text.
- Users must be able to dismiss command output.

## Acceptance

- The detail pane keeps command output opt-in after successful operations.
- Errors remain visible enough for recovery.
- Dismissing output clears the current command result.
- `swift test` and the app verification script pass.
