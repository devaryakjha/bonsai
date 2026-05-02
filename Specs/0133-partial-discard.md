# Spec 0133: Partial Discard

## Objective

Let users discard one unstaged hunk or line block from the diff viewer without
discarding the whole file.

## Requirements

- Partial discard must be opt-in from the diff action strip, not a persistent
  row-level control.
- Discarding a hunk must reverse-apply that hunk through Git's patch engine.
- Discarding a line block must reverse-apply the zero-context line patch through
  Git's patch engine.
- Partial discard must require confirmation before mutating the working tree.
- Staged diffs keep stage/unstage behavior; partial discard is only exposed for
  unstaged working-tree diffs in v0.

## Acceptance

- A user can discard one hunk while keeping another hunk in the same file.
- A user can discard one line block while keeping another line block in the same
  file.
- `swift test`, the app verification script, and whitespace checks pass.
