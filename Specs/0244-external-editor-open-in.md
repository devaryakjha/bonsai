# Spec 0244: External Editor Open In

## Intent

Close the current Fork release-note gap for external editor open-in actions
without adding noisy always-visible controls. Bonsai should let users send the
selected file to common macOS code editors from existing file-action menus.

## Requirements

- Keep the default `Open Selected File` action unchanged.
- Add an opt-in `Open In` submenu for selected files.
- Support Xcode, Visual Studio Code, Zed, Sublime Text, BBEdit, and Qt Creator
  through macOS bundle identifiers.
- Route launches through `FileOpenLauncher`; views must not shell out directly.
- Surface a concise command result when the requested editor is not installed.
- Expose the same editor list from the command menu, toolbar file menu, working
  tree rows, history file rows, and commit tree rows.

## Acceptance

- Unit coverage pins editor command titles and bundle identifiers.
- `swift test`, the app verifier, and whitespace checks pass.
