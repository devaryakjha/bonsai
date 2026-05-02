# Spec 0042: Calm Sidebar and Split Diff Polish

## Objective

Reduce first-glance information overload while preserving Fork-level feature
access for power users.

## Requirements

- Keep primary repository identity, recents/projects, active operations, and
  local branches visible in the sidebar.
- Move secondary metadata into opt-in disclosure groups with persisted expansion
  state.
- Keep optional branch upstream detail available without showing it inline for
  every branch row.
- Keep advanced features available through menus/context menus even when their
  sidebar detail sections are collapsed.
- Honor the toolbar label visibility setting so command text can be opt-in
  while icon buttons still expose hover and accessibility labels.
- Make split diff mode read as a complete side-by-side view with clear column
  headers.

## Acceptance

- Sidebar repository metrics and integrations are behind a Repository Details
  disclosure group.
- Remote branches, tags, remotes, worktrees, and submodules are behind opt-in
  disclosure groups.
- Local branch rows no longer show upstream names inline, while hover help still
  exposes upstream information.
- Toolbar labels are hidden by default but can be re-enabled from Settings.
- Split diff mode displays Before and After headers above the two panes.
- `swift test` and the app verification script pass.
