# Spec 0175: Annotated Tag Creation

## Objective

Let users create annotated tags from Bonsai without falling back to the terminal
or overloading the lightweight tag flow.

## Requirements

- The Git command menu exposes `Create Annotated Tag...`.
- The toolbar actions branch menu exposes `Create Annotated Tag...`.
- Commit history context menus expose `Create Annotated Tag Here...`.
- Local and remote branch context menus expose `Create Annotated Tag Here...`.
- The annotated tag sheet collects a tag name and tag message.
- Confirming creates an annotated tag with `git tag -a <name> -m <message>`.
- If a commit or branch reference launched the flow, the tag is created at that
  target rather than accidentally at `HEAD`.
- Existing lightweight tag creation remains unchanged.

## Acceptance

- Integration coverage proves an annotated tag created from a selected history
  commit has a tag object, stores the message, and points at the selected
  commit.
- Existing lightweight tag creation coverage continues to pass.
- `swift test`, the app verifier, and whitespace checks pass.
