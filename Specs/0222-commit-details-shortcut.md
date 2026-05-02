# Spec 0222: Commit Details Shortcut

## Objective

Make the existing opt-in commit-row details collapsible from the keyboard,
matching Fork's `Cmd+D` commit-details workflow.

## Requirements

- Preserve the existing default: compact one-line history rows.
- Keep the history header options menu and Settings toggle backed by the same
  stored preference.
- Add a macOS command menu action that toggles commit details.
- Bind the action to `Cmd+D`.
- Avoid adding persistent visible controls to the history pane.

## Acceptance

- The command toggles `bonsai.showCommitRowDetails`.
- Existing history row behavior stays unchanged.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
