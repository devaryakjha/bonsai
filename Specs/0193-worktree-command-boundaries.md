# Spec 0193: Worktree Command Boundaries

## Intent

Worktree creation, removal, and pruning are v0 Fork-parity operations. Their Git
arguments should be assembled through testable GitClient builders so branch and
force edge cases stay stable.

## Requirements

- Route worktree creation through a static argument builder.
- Preserve detached worktree creation with `--detach`.
- Preserve branch worktree creation with `-b <branch>`.
- Keep destination paths and branch names as single arguments.
- Route worktree removal and prune through static argument builders.
- Preserve `--force` only when force removal is requested.
- Do not change sidebar, toolbar, or menu reachability.

## Acceptance

- Command argument coverage proves detached and branch worktree creation.
- Command argument coverage proves normal and forced worktree removal.
- Command argument coverage proves worktree pruning.
- Validation gates pass.
