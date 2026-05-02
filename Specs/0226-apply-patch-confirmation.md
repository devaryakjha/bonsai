# Spec 0226: Apply Patch Confirmation

## Objective

Require confirmation before applying patch text from the macOS clipboard.

## Requirements

- Keep the existing `Apply Patch from Clipboard` command locations.
- Read clipboard text before showing the confirmation sheet.
- Show an error when the clipboard has no patch text.
- Present a compact confirmation sheet with a bounded patch preview.
- Apply the patch only after the user confirms.
- Continue routing patch application through Git's patch engine.
- Preserve the existing repository refresh and command-result behavior.

## Acceptance

- Integration coverage proves clipboard patch text opens a confirmation request
  and only applies after confirmation.
- Integration coverage proves an empty clipboard reports a user-facing error.
- `swift test`, the app verifier, and whitespace checks pass.
