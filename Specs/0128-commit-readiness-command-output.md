# Spec 0128: Commit Readiness Command Output

## Objective

Make locally blocked commit attempts visible in the same command result surface
as Git-backed commit failures.

## Requirements

- Commit attempts blocked by missing message or missing staged changes report a
  command result error.
- The command result title matches the active commit action: `Commit` or
  `Amend commit`.
- Existing `errorMessage` behavior remains unchanged.
- Blocked commit attempts do not clear the composer, reset options, or add
  recent commit messages.
- Successful commit and Git-backed failure behavior remains unchanged.

## Acceptance

- Store tests cover command output for a locally blocked normal commit.
- Existing failed commit preservation tests continue to pass.
- The app verification script, `swift test`, and whitespace checks pass.
