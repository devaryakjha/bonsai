# Spec 0219: Branch Worktree Indicator

## Objective

Show when a local branch is checked out in another linked worktree without
adding another visible metadata column to the sidebar.

## Requirements

- Keep local branch rows to one leading status icon.
- Preserve the current-branch checkmark as the highest-priority state.
- Show a worktree icon for local branches checked out in another worktree.
- Match worktrees to branches by full `refs/heads/...` names.
- Exclude the currently selected repository path when detecting other
  worktrees.
- Provide help text that names the linked worktree location.

## Acceptance

- Unit coverage proves current, linked-worktree, and available branch states.
- Local branch rows render the derived icon and help text.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
