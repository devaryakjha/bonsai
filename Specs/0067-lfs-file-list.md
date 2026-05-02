# Spec 0067: Git LFS File List

## Objective

Make detected Git LFS tracked files inspectable without adding noise to the
default sidebar.

## Requirements

- Git LFS files must appear behind an opt-in disclosure in repository details.
- Each row must show the tracked path and short object id.
- Each row must expose lock and unlock actions for that file.
- The list must stay hidden when Git LFS is unavailable or no LFS files are
  tracked.

## Acceptance

- The Git LFS integration row remains compact by default.
- Expanding the LFS files disclosure shows tracked paths.
- LFS file presentation is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
