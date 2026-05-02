# Spec 0075: Branch From Stash

## Objective

Let users turn a stash into a branch from Bonsai, matching a common desktop Git
stash workflow without requiring terminal commands.

## Requirements

- Stash row and toolbar stash menus must expose `Create Branch…`.
- The action must ask for a branch name through the existing operation sheet.
- Confirming must run `git stash branch <name> <stash>`.
- Repository state must refresh after the branch is created.

## Acceptance

- Branch-from-stash is reachable wherever stash apply/pop/drop are reachable.
- Store-level integration coverage proves the stash branch command creates and
  checks out the new branch.
- `swift test`, the app verification script, and whitespace checks pass.
