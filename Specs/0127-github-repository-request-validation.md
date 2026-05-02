# Spec 0127: GitHub Repository Request Validation

## Objective

Prevent invalid GitHub repository create/delete requests from reaching the
provider boundary when the store is called directly.

## Requirements

- Create requests require a non-empty normalized repository name.
- Delete requests require non-empty normalized owner and repository name.
- Invalid requests report a command result error instead of calling GitHub.
- Invalid requests keep the pending GitHub repository sheet open.
- Existing missing-token behavior stays unchanged.

## Acceptance

- Store tests cover invalid create and delete requests without live network
  calls.
- Valid request normalization remains covered separately.
- The app verification script, `swift test`, and whitespace checks pass.
