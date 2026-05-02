# Spec 0126: GitHub Repository Request Normalization

## Objective

Keep GitHub repository create/delete operations using the same normalized
owner/name/description values in provider calls and command output.

## Requirements

- Repository request owner and name trim leading and trailing whitespace.
- Empty repository descriptions normalize to `nil`.
- GitHub create uses the normalized repository name and optional description.
- GitHub delete uses the normalized owner/name for both the provider call and
  success output.
- Missing-token behavior and sheet state remain unchanged.

## Acceptance

- Model tests cover request normalization without live network calls.
- Existing GitHub request presentation tests continue to pass.
- The app verification script, `swift test`, and whitespace checks pass.
