# Remote Tracking Checkout Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Make remote branch checkout behave like a desktop Git client instead of a raw
detached checkout. Selecting a remote branch should create or switch to a local
tracking branch.

## Requirements

- Expose remote branch checkout as "Checkout as Local Branch".
- Derive the local branch name from the remote branch short name.
- If the local branch already exists, checkout that local branch.
- If it does not exist, execute `git checkout --track <remote>/<branch>`.
- Refresh refs and selected branch state after checkout.

## Acceptance Checks

- Integration tests cover checking out a fetched remote branch into a local
  tracking branch.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
