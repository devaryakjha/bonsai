# Spec 0199: Working Tree Command Boundaries

## Intent

Working-tree mutations are the everyday safety surface of a Git client. Stage,
unstage, discard, patch application, commit, and repository transfer shortcuts
must have explicit command boundaries so UI polish does not hide risky argument
construction.

## Requirements

- Route single-file and bulk staging through static argument builders.
- Route single-file and bulk unstaging through static argument builders.
- Route untracked clean and tracked worktree restore discard paths through
  static argument builders.
- Route hunk, line, and full-patch application through static argument builders.
- Route commit and repository fetch, pull, and push actions through static
  argument builders.
- Preserve file paths and commit messages as single arguments, including spaces.
- Keep empty bulk staging and unstaging as no-op execution behavior.

## Acceptance

- Command argument coverage proves stage and stage-all path handling.
- Command argument coverage proves unstage behavior with and without `HEAD`.
- Command argument coverage proves untracked and tracked discard commands.
- Command argument coverage proves hunk, line, and full-patch apply commands.
- Command argument coverage proves commit flags and fetch, pull, push actions.
- SwiftPM tests and the app verifier pass.
