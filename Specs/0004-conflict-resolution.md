# Conflict Resolution Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Provide a v0 merge-conflict workflow inside Bonsai so conflicted files are not
dead-end status rows.

## Requirements

- Conflicted files are grouped in the working tree.
- A conflicted file can open a resolver sheet from the row action or context menu.
- The resolver previews the current working-tree file content.
- The diff viewer can compare an externally edited conflict resolution against
  base, ours, or theirs while the file is still conflicted.
- User can accept ours, accept theirs, or mark the file resolved.
- Git operations refresh repository state and report command output.

## Acceptance Checks

- Conflict actions live in `GitClient`.
- Views do not shell out directly.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
