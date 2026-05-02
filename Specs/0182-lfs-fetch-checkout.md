# Spec 0182: Git LFS Fetch and Checkout

## Intent

Git LFS users sometimes need to download LFS objects without immediately
rewriting the working tree, or materialize already-fetched objects into pointer
files. Bonsai should expose those repo-wide LFS operations without adding
working-tree chrome.

## Requirements

- Expose `Fetch` and `Checkout Files` inside the existing Git LFS toolbar menu
  and command menu.
- Keep both actions disabled when no repository is selected or Git LFS is
  unavailable.
- Execute `git lfs fetch` and `git lfs checkout` through `GitClient`.
- Keep repo-wide LFS actions visually separated from selected-file lock actions
  inside the menu.
- Report command results as `Git LFS fetch` and `Git LFS checkout`.

## Acceptance

- Command argument tests cover the LFS fetch and checkout invocations.
- Existing LFS pull, prune, lock, and unlock actions remain reachable.
- Validation gates pass.
