# Spec 0253: Apply Patch Clipboard Shortcut

## Intent

Close Fork's `Cmd+V` apply-patch release-note delta while preserving Bonsai's
explicit confirmation flow before any patch mutates the repository.

## Requirements

- Keep the existing `Apply Patch from Clipboard` toolbar and Git menu locations.
- Add a macOS keyboard shortcut for the Git menu command using `Cmd+V`.
- Keep the command disabled when no repository is selected.
- Preserve the existing clipboard validation and confirmation sheet.
- Do not apply patch text directly from the shortcut without confirmation.

## Acceptance

- The Git menu `Apply Patch from Clipboard` command advertises `Cmd+V`.
- Existing apply-patch integration tests still prove confirmation is required.
- `Specs/0243-fork-release-parity-refresh.md` records the release-note delta as
  covered.
- `swift test`, the app verifier, release packaging verifier, and whitespace
  checks pass.
