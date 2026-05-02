# Blame View Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Replace the raw blame command output with a native structured blame view. Fork's
file inspection surfaces make authorship, commit identity, and line content easy
to scan; Bonsai needs the same baseline without losing Git as the source of
truth.

## Requirements

- Load blame data with `git blame --line-porcelain -- <path>`.
- Parse line porcelain into structured rows with commit hash, author, author
  email, author date, final line number, original line number, and source text.
- Present blame from the selected working-tree or history file in a dense native
  sheet instead of raw command output.
- Keep line content monospaced and horizontally scrollable so source code does
  not wrap or reflow unexpectedly.
- Report Git errors through the existing command result/error path.

## Acceptance Checks

- Parser tests cover multi-author porcelain blame output.
- Integration tests prove `GitClient` returns structured blame lines for a real
  repository.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
