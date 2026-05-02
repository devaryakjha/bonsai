# Spec 0116: Repository Setup Confirmation

## Objective

Make repository setup completion behave like a complete desktop Git-client
entry flow for both newly created and cloned repositories.

## Requirements

- Creating a repository initializes the destination and opens it in Bonsai.
- Newly initialized empty repositories refresh without treating the missing
  first commit as an error.
- Cloning a repository opens the clone destination in Bonsai.
- Successful setup records the opened repository in recents.
- Successful setup keeps the command result visible after repository selection
  changes.

## Acceptance

- Store integration tests cover create and clone setup confirmation.
- Empty repositories snapshot with an empty commit list.
- Setup commands remain behind `GitClient`.
- `swift test`, the app verification script, and whitespace checks pass.
