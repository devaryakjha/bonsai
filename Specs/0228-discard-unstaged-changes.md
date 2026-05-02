# Spec 0228: Discard Unstaged Changes

## Objective

Let users discard all current unstaged working-tree changes from Bonsai without
repeating the file-by-file discard flow.

## Requirements

- Expose the action from menu-based command surfaces, not as another persistent
  row control.
- Require explicit confirmation before mutating the working tree.
- Discard tracked unstaged edits through `git restore --worktree`.
- Remove untracked files through `git clean -f`.
- Do not include staged, conflicted, or ignored rows in the bulk discard set.
- Preserve the existing single-file discard confirmation behavior.

## Acceptance

- Command argument coverage proves tracked and untracked paths are grouped
  separately.
- Store coverage proves the request captures only unstaged, non-ignored rows.
- Integration coverage proves bulk discard removes both tracked edits and
  untracked files.
- `swift test`, the app verifier, and whitespace checks pass.
