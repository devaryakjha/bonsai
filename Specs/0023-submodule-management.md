# Submodule Management Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Make submodules visible and actionable as first-class repository items. Bonsai
already loads submodule status and can run a global update, but Fork parity needs
users to inspect and act on submodules without a terminal.

## Requirements

- Show submodules in the sidebar with path, status, and commit.
- Decode common `git submodule status` state markers into user-readable labels.
- Let users update one selected submodule.
- Let users open a submodule as the active repository.
- Keep the existing global recursive update action.

## Acceptance Checks

- Parser tests cover initialized, uninitialized, changed, and conflicted
  submodule states.
- Integration tests cover listing and updating a real local submodule.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
