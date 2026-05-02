# Spec 0252: Claude Branch Review

## Intent

Close the Claude branch-review portion of Fork's AI parity delta with an
opt-in review action that runs through the installed Claude Code CLI.

## Requirements

- Add a toolbar Tools action for reviewing the current branch with Claude Code.
- Keep the action disabled when no repository, no current branch, or a review is
  already running.
- Compare the current branch against its upstream when available, with a
  repository default-branch fallback.
- Feed Claude a bounded branch diff plus diffstat and request review findings,
  risks, and test gaps.
- Present the review in a dedicated sheet with copy and close actions.
- Do not modify files, commits, branches, or the working tree during review.
- Surface missing Claude Code or empty branch-diff failures through the existing
  command-result area.

## Acceptance

- `Tools > Inspect` exposes `Review Current Branch with Claude`.
- Claude branch review prompt construction and Git argument boundaries are
  unit-tested.
- `Specs/0242-v0-parity-evidence.md` records the Claude branch-review and
  generated-commit-message delta as covered.
- `swift test`, app verifier, release packaging verifier, and whitespace checks
  pass.
