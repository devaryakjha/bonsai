# Spec 0286: Stale Local Branch Selection

## Intent

Cover Fork 2.62's stale local branch workflow without adding more always-visible
sidebar noise.

## Requirements

- Detect local branches whose upstream is gone.
- Exclude the currently checked out branch from stale branch deletion.
- Expose the workflow as an opt-in action from the local branches section.
- Present stale branches in a review sheet with all branches selected by
  default.
- Let users deselect branches before deletion.
- Keep force deletion explicit for unmerged local branches.
- Delete selected branches through `git branch -d` or `git branch -D` using
  repository-scoped GitClient commands.

## Acceptance

- Unit coverage proves bulk branch deletion arguments preserve branch names and
  force mode.
- Unit coverage proves stale branch request copy stays concise.
- Integration coverage proves stale local branches can be selected and deleted
  while the current branch remains protected.
