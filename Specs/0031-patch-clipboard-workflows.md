# Patch Clipboard Workflows Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Add patch clipboard workflows that match modern Git client expectations: users
should be able to copy the currently inspected diff as a patch and apply a patch
from the macOS clipboard without leaving Bonsai.

## Requirements

- Expose a Copy Patch action when the current diff text is non-empty.
- Copy the exact current unified diff text to the macOS pasteboard.
- Expose an Apply Patch from Clipboard action for the selected repository.
- Apply clipboard patch text through Git's patch engine rather than manually
  editing files.
- Refresh repository state after applying a patch.
- Show user-facing errors when the clipboard is empty or Git rejects the patch.

## Acceptance Checks

- Integration tests prove a patch string can be applied to a real repository.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
