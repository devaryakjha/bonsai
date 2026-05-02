# Spec 0181: Git LFS Prune

## Intent

Git LFS repositories can accumulate local objects that are no longer needed.
Fork-style Git LFS support should let users prune that cache from Bonsai without
adding another always-visible control.

## Requirements

- Expose `Prune` inside the existing Git LFS toolbar menu and command menu.
- Keep the action disabled when no repository is selected or Git LFS is
  unavailable.
- Execute `git lfs prune` through `GitClient`.
- Report the command as `Git LFS prune` in the command result area.

## Acceptance

- Command argument tests cover the LFS prune invocation.
- Existing LFS selected-file actions remain unchanged.
- Validation gates pass.
