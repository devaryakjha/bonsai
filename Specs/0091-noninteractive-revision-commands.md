# Spec 0091: Noninteractive Revision Commands

## Objective

Ensure revision actions never depend on a terminal editor or interactive Git
prompt when launched from Bonsai.

## Requirements

- Cherry-pick, revert, and merge actions must pass `--no-edit` so Git uses its
  default commit messages without opening an editor.
- Rebase keeps its normal non-interactive `git rebase <commit>` invocation.
- The typed revision command model owns the final argument list for each action.
- Existing command result copy and menu reachability remain unchanged.

## Acceptance

- Unit tests cover the exact Git argument list for every revision command.
- Existing merge and cherry-pick integration coverage still goes through the
  typed command path.
- `swift test`, the app verification script, and whitespace checks pass.
