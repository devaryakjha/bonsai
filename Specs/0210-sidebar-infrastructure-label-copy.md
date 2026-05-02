# Spec 0210: Sidebar Infrastructure Label Copy

## Intent

Keep the infrastructure sidebar sections calm and professional by using noun
labels instead of imperative `Show...` copy.

## Requirements

- Worktree, remote, and submodule disclosure rows use category/status labels,
  not `Show` commands.
- Empty worktree and remote disclosures keep their add/create actions reachable.
- Disclosure rows keep counts visible before expansion.
- Preserve the separated Worktrees, Remotes, and Submodules sections.

## Acceptance

- Worktrees render as `Linked worktrees` or `No linked worktrees`.
- Remotes render as `Configured remotes` or `No configured remotes`.
- Submodules render as `Repository submodules`.
- Sidebar infrastructure copy is covered by focused unit tests.
- SwiftPM tests, app verifier, and whitespace checks pass.
