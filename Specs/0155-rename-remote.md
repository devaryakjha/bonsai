# Spec 0155: Rename Remote

## Objective

Complete remote editing by letting users rename an existing remote without
removing and re-adding it manually.

## Requirements

- The remote edit sheet allows changing the remote name as well as the URL.
- Saving a changed remote name runs `git remote rename <old> <new>`.
- Saving a changed URL still runs `git remote set-url <name> <url>`.
- When both name and URL change, rename happens before updating the URL.
- Repository state refreshes through the existing mutation pipeline.
- Existing add, fetch, copy URL, and remove remote actions remain unchanged.

## Acceptance

- Integration coverage proves a remote can be renamed and have its URL updated
  in one save operation.
- The old remote name is gone and the new name has the updated fetch URL.
- `swift test`, the app verification script, and whitespace checks pass.
