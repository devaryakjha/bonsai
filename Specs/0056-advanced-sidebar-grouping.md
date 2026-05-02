# Spec 0056: Advanced Sidebar Grouping

## Objective

Make the advanced sidebar disclosure readable by separating worktrees, remotes,
and submodules into distinct groups instead of one flat mixed list.

## Requirements

- Worktrees, remotes, and submodules must render under separate visible headers.
- Each group header must include a count so the section is scannable while
  collapsed visually within the disclosure body.
- Existing actions must remain reachable: create worktree, open/remove
  worktree, add/edit/remove remote, open/update submodule.
- Row content must stay compact and native to the sidebar: one leading icon,
  one title, and at most two detail lines.
- The disclosure label must use Git vocabulary and say `submodules`, not the
  vague `modules`.

## Acceptance

- The advanced disclosure no longer appears as one undifferentiated list.
- Worktree paths and remote URLs remain visible but subordinate to the group and
  item identity.
- `swift test`, the app verification script, and whitespace checks pass.
