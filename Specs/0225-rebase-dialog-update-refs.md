# Spec 0225: Rebase Dialog Update Refs

## Objective

Let users opt into Git's `--update-refs` behavior when rebasing onto a selected
revision.

## Requirements

- Add an `Update refs` option to the selected-revision rebase confirmation
  sheet.
- Show the option only for rebase, not cherry-pick, revert, or merge.
- Keep the option off by default each time the sheet opens.
- Pass `--update-refs` only for rebase commands when enabled.
- Preserve existing confirmation copy and command result behavior.

## Acceptance

- Unit coverage proves rebase arguments include `--update-refs` only when
  enabled.
- Existing revision command tests continue to pass.
- `swift test`, the app verifier, and whitespace checks pass.
