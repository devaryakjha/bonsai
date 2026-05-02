# Spec 0080: GitHub Delete Confirmation

## Objective

Make GitHub repository deletion match the safety expected from a native Git
client by requiring an explicit repository-name confirmation before calling the
provider API.

## Requirements

- Delete GitHub Repository should prefill owner and name from a GitHub remote
  when one is available.
- The delete sheet must require the user to type `owner/name` before the
  destructive button is enabled.
- The destructive button must use a destructive role.
- GitHub owner/name derivation must support common HTTPS and SSH GitHub remote
  URL formats.
- Network calls remain isolated in `GitHubClient`.

## Acceptance

- GitHub remote target derivation is covered by unit tests.
- Delete remains unavailable until the typed confirmation exactly matches the
  owner/name target.
- `swift test`, the app verification script, and whitespace checks pass.
