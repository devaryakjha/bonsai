# Spec 0240: Toolbar Tools Menu Grouping

## Intent

Keep the toolbar Tools menu calm as utility and parity actions accumulate. The
menu should stay complete, but actions should be grouped by workflow instead of
appearing as one long mixed list.

## Requirements

- Inspection actions live under `Inspect`.
- Patch clipboard actions live under `Patch`.
- Selected-file and working-tree file actions live under `File`.
- Repository maintenance actions live under `Repository`.
- Git LFS, GPG, Git-flow, and hosting actions live under `Integrations`.
- Existing action routing and enabled/disabled behavior remain unchanged.
- Menu labels remain short and professional.

## Acceptance

- Unit coverage pins toolbar Tools menu group labels.
- `swift test`, the app verifier, and whitespace checks pass.
