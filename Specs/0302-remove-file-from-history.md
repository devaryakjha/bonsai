# Spec 0302: Purge file from Git history

## Objective

Let users purge a committed file from local Git history without opening a
terminal.

## Requirements

- Expose the operation as an opt-in destructive menu action named `Purge file
  from Git history…`.
- Accept a repository-relative path, with the selected file path prefilled when
  one is available.
- Require explicit confirmation before rewriting history.
- Require a clean working tree before the rewrite starts.
- Scan all local refs for commits referencing the path before mutating history.
- Rewrite local branches and tags so the path is removed wherever it appears.
- Remove filter-branch backup refs, expire reflogs, and prune unreachable
  objects after a successful rewrite.
- Report the number of commits that referenced the path.
- Leave remote publication to the user; Bonsai should not force-push as part of
  this action.

## Acceptance

- Command argument coverage proves the history scan, filter-branch rewrite, and
  cleanup commands.
- Integration coverage proves a committed `.env` file is removed from reachable
  history while the ignored working-copy file remains on disk.
- The operation is routed through `GitClient` and `RepositoryStore`; views do
  not shell out directly.
- `swift test` passes.
