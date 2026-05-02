# Spec 0101: Preserve Failed Commit Message

## Objective

Prevent commit composer data loss when Git rejects a commit.

## Requirements

- Failed commit attempts keep the current commit message in the composer.
- Failed commit attempts keep the current amend and signing options unchanged.
- Failed commit attempts do not add the message to recent commit messages.
- Successful commits keep the current behavior: clear the message, reset amend,
  and remember the message.
- Mutation success or failure is reported by the store boundary.

## Acceptance

- Failed commit behavior is covered by integration tests.
- Existing successful commit workflows continue to pass.
- `swift test`, the app verification script, and whitespace checks pass.
