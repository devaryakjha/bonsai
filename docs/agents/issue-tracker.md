# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`.
- **Read an issue**: `gh issue view <number> --comments`.
- **List issues**: `gh issue list --state open` with the needed label filter.
- **Comment on an issue**: `gh issue comment <number> --body "..."`.
- **Apply or remove labels**: `gh issue edit <number> --add-label "..."` or `--remove-label "..."`.
- **Close an issue**: `gh issue close <number> --comment "..."`.

Infer the repository from `git remote -v`. The `gh` CLI does this inside this clone.

## Pull requests as a triage surface

**PRs as a request surface: no.**

## When a skill uses the issue tracker

Create a GitHub issue when a skill says to publish work to the issue tracker.

Run `gh issue view <number> --comments` when a skill says to fetch a relevant ticket.
