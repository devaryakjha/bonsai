# Spec 0108: Working Tree Section Actions

## Objective

Make bulk staging available from the working-tree panel without adding more row
metadata or verbose controls.

## Requirements

- The Unstaged section exposes a compact icon action for Stage All when
  unstaged, non-conflicted changes are present.
- The Staged section exposes a compact icon action for Unstage All when staged
  changes are present.
- Bulk section actions route through `RepositoryStore`.
- Empty staged and unstaged sections remain visually quiet.
- Header controls use hover help and accessibility labels for explanatory copy
  instead of always-visible text.

## Acceptance

- Users can stage all visible unstaged changes from the Unstaged section header.
- Users can unstage all staged changes from the Staged section header.
- Row content remains unchanged.
- `swift test`, the app verification script, and whitespace checks pass.
