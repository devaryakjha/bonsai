# Line Staging Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Close the parity gap between coarse hunk staging and Fork-style line-by-line
staging. Bonsai should let users stage or unstage a targeted changed line block
without staging the entire surrounding hunk.

## Requirements

- Parse changed line blocks from Git hunks while preserving exact file headers.
- Build zero-context patches for selected additions, deletions, and replacement
  blocks.
- Apply line patches to the index with Git's patch engine rather than mutating
  files directly.
- Use `git apply --cached --unidiff-zero` for staging line patches.
- Use `git apply --cached --reverse --unidiff-zero` for unstaging line patches.
- Expose line staging from the diff action strip for working-tree diffs.

## Acceptance Checks

- Parser tests cover line-change patch extraction.
- Integration tests prove one line block can be staged while another remains
  unstaged.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
