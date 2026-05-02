# Spec 0098: Workspace Group Actions

## Objective

Make `~/projects` workspace groups manageable with the same opt-in filesystem
actions used for repository rows.

## Requirements

- Workspace groups retain their compact title plus repository count layout.
- Workspace groups expose the resolved folder path through hover help.
- Workspace group context menus expose Copy Path and Reveal in Finder.
- Workspace group actions route through `RepositoryStore`.
- Workspace group paths are produced by `ProjectRepositoryScanner`.

## Acceptance

- Users can copy or reveal a scanned workspace group folder without expanding
  or opening a repository.
- Workspace group paths are covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
