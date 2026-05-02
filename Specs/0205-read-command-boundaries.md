# Spec 0205: Read Command Boundaries

## Intent

Repository refresh and inspection reads are as important to Fork-parity behavior
as mutations. Their Git command arguments should be explicit and testable so
status, history, refs, diffs, reflog, blame, and file-history views stay stable.

## Requirements

- Move high-use read command arrays behind static `GitClient` argument builders.
- Cover refresh reads for status, commit lists, refs, remotes, stashes,
  submodules, and worktrees.
- Cover inspection reads for changed files, tree browsing, blob text, commit
  diffs, stash patches, reflog, blame, file history, and line history.
- Preserve all current Git behavior and parser inputs.

## Acceptance

- Focused command-argument tests cover the new read builders.
- Existing Git integration tests continue to prove the commands execute against
  real repositories.
- SwiftPM tests, the app verifier, and whitespace checks pass.
