# Git-flow Finish Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Complete the v0 Git-flow surface by adding finish commands for feature, release,
and hotfix flows. Bonsai already detects Git-flow, initializes it, and starts new
flows; users also need to finish them without leaving the app.

## Requirements

- Expose feature/release/hotfix finish actions when Git-flow is initialized.
- Collect the flow name in the existing operation sheet.
- Execute `git flow <kind> finish <name>` through `GitClient`.
- Refresh repository state after a finish command.

## Acceptance Checks

- Unit tests cover operation kind mapping for start and finish actions.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
