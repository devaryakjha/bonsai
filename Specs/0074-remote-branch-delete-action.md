# Spec 0074: Remote Branch Delete Action

## Objective

Expose the existing remote-branch deletion workflow from the remote branch list
so reference management is complete from the sidebar.

## Requirements

- Remote branch context menus must include a destructive `Delete` action.
- Deleting a remote branch must use the existing confirmation sheet.
- Confirming deletion must remove the remote branch through the store/Git client
  path, not view-layer shelling.
- Local branch and tag deletion behavior must remain unchanged.

## Acceptance

- Remote branches, local branches, and tags all have reachable delete actions.
- Store-level integration coverage proves confirming a remote branch deletion
  removes the remote-tracking ref.
- `swift test`, the app verification script, and whitespace checks pass.
