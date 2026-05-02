# Spec 0180: Git LFS Force Unlock

## Intent

Git LFS users sometimes need to unlock files they no longer own locally, or clear
stale locks. Bonsai already has the GitClient path for forced unlocks, but v0
should make the action reachable without adding visible working-tree clutter.

## Requirements

- Expose `Force Unlock` for LFS file rows.
- Expose `Force Unlock Selected File` from Git LFS command and toolbar menus.
- Keep force unlock opt-in inside existing Git LFS menus/context menus.
- Use `git lfs unlock --force <path>` through `GitClient`.
- Use command result titles that distinguish normal unlock from force unlock.

## Acceptance

- Command argument tests cover normal and forced unlock argument order.
- Existing selected-file LFS readiness behavior remains unchanged.
- Validation gates pass.
