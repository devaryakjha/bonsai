# Repository Manager Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Make repository entry match the first practical Fork workflow: open an existing
repo, clone a remote repo, create a new local repo, and quickly return to local
project repositories.

## Requirements

- Existing repositories can be opened through a native directory picker.
- `~/projects` is scanned on launch and can be rescanned manually.
- Clone accepts a remote URL and destination directory.
- Create initializes a local Git repository at a selected destination.
- Successful clone/create opens the repository, records it in recents, and
  refreshes the main window.
- Failures surface the Git/process output without losing current app state.

## Acceptance Checks

- `swift test` covers destination derivation and scanner behavior.
- `./script/build_and_run.sh --verify` builds and launches the app bundle.
- Clone/create commands live behind `GitClient` rather than view code.
