# Spec 0079: Calm Infrastructure Sidebar Rows

## Objective

Reduce visual load in the sidebar infrastructure groups without removing access
to worktree paths or remote URLs.

## Requirements

- Worktree rows show the worktree name and state only; full filesystem paths
  stay available through hover help.
- Remote rows show the remote name and a short capability label instead of the
  full URL; fetch and push URLs stay available through hover help.
- Existing context-menu actions for worktrees and remotes remain unchanged.
- Row height stays stable so the infrastructure groups scan like native macOS
  sidebar rows.

## Acceptance

- Worktree filesystem paths are no longer always visible in the sidebar.
- Remote URLs are no longer always visible in the sidebar.
- `swift test`, the app verification script, and whitespace checks pass.
