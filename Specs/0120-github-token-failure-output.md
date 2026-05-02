# Spec 0120: GitHub Token Failure Output

## Objective

Make missing GitHub token failures visible in the same command result area as
provider network failures.

## Requirements

- GitHub notification fetch reports a command result when no token is configured.
- GitHub notification mark-read reports a command result when no token is
  configured.
- GitHub repository create/delete reports a command result when no token is
  configured.
- Missing-token handling does not dismiss pending GitHub repository sheets.

## Acceptance

- Store tests cover missing-token output for notification and repository
  actions without live network calls.
- The token remains read from Settings-backed `AppStorage`.
- `swift test`, the app verification script, and whitespace checks pass.
