# Spec 0183: Remote Branch Delete Boundary

## Intent

Remote branch deletion is already exposed from the sidebar, but the raw push
command should live behind `GitClient` like other Git mutations. Pseudo refs
such as `origin/HEAD` must not expose a destructive delete action.

## Requirements

- Route remote branch deletion through `GitClient`.
- Execute remote branch deletion as `git push <remote> --delete <branch>`.
- Reject refs that do not resolve to a concrete remote branch name.
- Hide the destructive delete action for remote pseudo refs.
- Preserve the existing confirmation sheet for real remote branches.

## Acceptance

- Command argument tests cover valid remote branch deletion.
- Command argument tests reject invalid remote branch refs.
- Existing remote branch delete integration behavior remains unchanged.
- Validation gates pass.
