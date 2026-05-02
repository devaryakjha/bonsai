# Branch Upstream Management Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Let users repair or remove branch upstream tracking from Bonsai. Since the
sidebar already displays ahead/behind and gone upstream state, it should also
provide the basic tracking controls users expect from a Git client.

## Requirements

- Expose an Unset Upstream action on local branches with an upstream.
- Expose a Set as Upstream for Current Branch action on remote branches.
- Execute upstream changes through Git branch commands.
- Refresh refs after upstream changes.
- Keep checkout, rename, and delete behavior unchanged.

## Acceptance Checks

- Integration tests cover unsetting and restoring upstream tracking.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
