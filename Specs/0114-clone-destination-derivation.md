# Spec 0114: Clone Destination Derivation

## Objective

Keep clone setup predictable by centralizing how Bonsai derives the destination
folder from a selected parent folder and remote URL.

## Requirements

- Clone destination derivation lives in one store helper.
- HTTPS, SSH URL, and SCP-style Git remotes derive the repository folder name.
- Empty remote input keeps the existing `Repository` fallback.
- The clone setup sheet uses the shared helper when a parent folder is chosen
  and when the remote URL changes.

## Acceptance

- Repository setup tests cover destination derivation from common remote formats.
- Existing clone/create behavior remains unchanged.
- `swift test`, the app verification script, and whitespace checks pass.
