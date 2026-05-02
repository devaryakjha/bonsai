# Spec 0069: Publish Untracked Branch

## Objective

Make pushing a new local branch work like a desktop Git client instead of
surfacing Git's missing-upstream failure by default.

## Requirements

- When the current branch has no upstream and a remote exists, the primary push
  action must become `Publish`.
- Publishing must run `git push -u <remote> <branch>` so future pushes use the
  configured upstream.
- Prefer `origin` as the publish remote when it exists, otherwise use the first
  configured remote.
- Normal fetch, pull, and push behavior must stay unchanged for branches that
  already have upstream tracking.

## Acceptance

- Toolbar and menu push labels show `Publish` for an untracked current branch
  with a remote.
- Publishing a local branch creates the remote branch and records upstream
  tracking.
- `swift test`, the app verification script, and whitespace checks pass.
