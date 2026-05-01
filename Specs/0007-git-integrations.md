# Git Integrations Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Cover the v0 integration surfaces called out by Fork parity: Git LFS, GPG
signing, and Git-flow.

## Requirements

- Detect whether Git LFS is available and list tracked LFS files when possible.
- Expose a Git LFS pull action.
- Detect repository commit signing config and configured signing key.
- Expose a commit signing toggle at repository config level.
- Detect whether Git-flow is available and initialized for the repository.
- Expose Git-flow init and feature/release/hotfix start commands.

## Acceptance Checks

- Integration status is part of the repository snapshot.
- Integration commands live in `GitClient`.
- Views do not shell out directly.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
