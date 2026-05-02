# Spec 0115: GPG Signing Config Toggle

## Objective

Make the repository-level GPG signing action verifiable as part of Bonsai's v0
Fork-parity integration surface.

## Requirements

- The store-level signing action writes Git's `commit.gpgsign` config.
- Enabling signing refreshes integration status to show signing on.
- Disabling signing refreshes integration status to show signing off.
- The command result reflects the signing action that ran.
- The commit composer signing toggle remains a per-commit option and is not
  changed by this repository config action.
- The commit composer summary reflects repository-level signing when
  `commit.gpgsign` is enabled.

## Acceptance

- Integration tests cover enabling and disabling repository signing config.
- Unit coverage verifies the composer summary reflects repository signing.
- Signing config commands remain behind `GitClient`.
- `swift test`, the app verification script, and whitespace checks pass.
