# Spec 0224: Interactive Rebase Update Refs

## Objective

Let users opt into Git's `--update-refs` behavior when starting an interactive
rebase.

## Requirements

- Add an `Update refs` option to the interactive rebase sheet.
- Keep the option off by default.
- Store the option on the current rebase plan so it is submitted with the plan.
- Pass `--update-refs` to `git rebase -i` only when the option is enabled.
- Keep the todo-file preview and existing rebase validation unchanged.

## Acceptance

- Unit coverage proves command arguments include `--update-refs` only when the
  plan requests it.
- Existing interactive rebase plan tests continue to pass.
- `swift test`, the app verifier, and whitespace checks pass.
