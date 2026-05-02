# Spec 0145: Open Repository In Terminal

## Objective

Support the common desktop Git-client workflow of opening repository paths in
Terminal without adding persistent sidebar chrome.

## Requirements

- The Repository command menu exposes `Open in Terminal` for the selected
  repository.
- Repository header, recent repository, workspace repository, and workspace
  group context menus expose `Open in Terminal`.
- Opening Terminal uses the repository or workspace-group directory, not a
  selected file.
- The action routes through `RepositoryStore`.
- Existing copy-path and Reveal in Finder actions remain unchanged.

## Acceptance

- Unit tests cover the Terminal launch arguments so spaces and full paths are
  passed as one argument.
- The app still builds and runs through the macOS verifier.
