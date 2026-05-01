# Workspace Groups Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Make Bonsai usable for developers with many local repositories by grouping
`~/projects` repositories into workspace-style sections.

## Requirements

- Repositories directly under `~/projects` appear in a root workspace group.
- Repositories nested under a first-level folder appear in a group named after
  that folder.
- Grouping must not descend into child repositories once a `.git` directory is
  found.
- The sidebar shows workspace groups with repository counts and open actions.
- Rescanning `~/projects` refreshes both the grouped and flat repository caches.

## Acceptance Checks

- Workspace grouping is covered by unit tests.
- The implementation stays in `ProjectRepositoryScanner`/`RepositoryStore`.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
