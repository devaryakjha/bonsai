# Spec 0053: Toolbar Action Consolidation

## Objective

Reduce default toolbar load while preserving access to the full repository
operation set expected from a desktop Git client.

## Requirements

- Keep high-frequency repository actions directly visible: open, new, refresh,
  fetch, pull, and push.
- Move lower-frequency branch, revision, stash, integration, and repository
  utility operations behind one toolbar menu.
- Preserve every command that was available from the toolbar before this pass.
- Keep macOS command-menu access unchanged for keyboard and menu-bar workflows.
- Toolbar labels must remain compact when label display is enabled.

## Acceptance

- The toolbar shows one consolidated secondary action menu after fetch/pull/push.
- Branch, revision, stash, and tools commands remain reachable from the
  consolidated menu.
- `swift test`, the app verification script, and whitespace checks pass.
