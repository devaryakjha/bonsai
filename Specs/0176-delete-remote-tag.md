# Spec 0176: Delete Remote Tag

## Objective

Let users remove a pushed tag from a remote without deleting the local tag or
using the terminal.

## Requirements

- Tag context menus expose a `Delete from Remote` submenu when remotes are
  available.
- Selecting a remote opens a confirmation sheet before deleting the remote tag.
- Confirming deletes `refs/tags/<tag>` from the selected remote.
- The local tag remains in the repository.
- Existing local tag delete, tag push, rename, checkout, merge, rebase, copy,
  and browser actions remain available.

## Acceptance

- Integration coverage proves a pushed tag can be deleted from a bare remote
  while the local tag remains.
- The command result names the tag and remote.
- `swift test`, the app verifier, and whitespace checks pass.
