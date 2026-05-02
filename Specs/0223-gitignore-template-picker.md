# Spec 0223: Gitignore Template Picker

## Objective

Let users add a `.gitignore` from a curated template without leaving Bonsai.

## Requirements

- Add a Git menu action named `Add .gitignore Template...`.
- Present a native picker sheet with searchable, single-selection templates.
- Keep the working-tree row ignore actions unchanged.
- Apply templates by appending only patterns that are not already present.
- Preserve existing `.gitignore` content and comments.
- Route the mutation through `RepositoryStore` and refresh repository state.
- Keep the template catalog local so the picker works offline.

## Acceptance

- Unit coverage proves the catalog exposes useful templates and unique IDs.
- Integration coverage proves applying a template writes `.gitignore`, skips
  duplicate patterns, and refreshes the status surface.
- `swift test`, the app verifier, and whitespace checks pass.
