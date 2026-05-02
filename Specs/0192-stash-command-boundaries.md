# Spec 0192: Stash Command Boundaries

## Intent

Stash management is a v0 Fork-parity surface. Stash mutation commands should be
assembled through testable GitClient argument builders instead of inline arrays.

## Requirements

- Route stash push through a static argument builder.
- Preserve the default `git stash push` command.
- Preserve `--include-untracked` before the optional message when requested.
- Preserve stash apply, pop, drop, and branch arguments.
- Keep stash messages, branch names, and stash references as single arguments.
- Do not change stash UI reachability.

## Acceptance

- Command argument coverage proves tracked and include-untracked stash push.
- Command argument coverage proves stash apply and pop.
- Command argument coverage proves stash drop and branch-from-stash.
- Validation gates pass.
