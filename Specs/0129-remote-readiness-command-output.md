# Spec 0129: Remote Readiness Command Output

## Objective

Make locally blocked pull and push attempts visible in the command result
surface, matching other primary action failures.

## Requirements

- Pull attempts blocked by readiness checks report a command result error.
- Push attempts blocked by readiness checks report a command result error.
- Command result titles stay short: `Pull` and the active push action title.
- Existing `errorMessage` behavior remains unchanged.
- Valid push, publish, fetch, and pull operations remain unchanged.

## Acceptance

- Store integration tests cover command output for blocked pull and push.
- Publish behavior for untracked branches remains covered separately.
- The app verification script, `swift test`, and whitespace checks pass.
