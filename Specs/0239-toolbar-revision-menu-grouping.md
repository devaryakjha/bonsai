# Spec 0239: Toolbar Revision Menu Grouping

## Intent

Keep the toolbar revision menu usable as revision parity grows. Selected-commit
commands, in-progress operation controls, interactive rebase, and bisect should
be grouped by workflow instead of appearing as one long mixed list.

## Requirements

- Selected commit mutation actions live under `Selected Commit`.
- Continue, skip, and abort controls live under `Current Operation`.
- Interactive rebase lives under `Rebase`.
- Bisect start, mark, and reset actions live under `Bisect`.
- Existing enabled/disabled behavior remains unchanged.
- Menu labels remain short and professional.

## Acceptance

- Unit coverage pins toolbar revision menu group labels.
- `swift test`, the app verifier, and whitespace checks pass.
