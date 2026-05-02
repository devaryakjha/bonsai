# Spec 0065: Force Delete Local Branch

## Objective

Support force deletion of unmerged local branches without making destructive
branch deletion easy to trigger accidentally.

## Requirements

- Local branch deletion confirmation must expose an opt-in force delete toggle.
- Force delete must use `git branch -D` only for local branches.
- Remote branch and tag deletion must not show the force option.
- Opening a new delete confirmation must reset the force option.

## Acceptance

- Normal local branch deletion keeps using `git branch -d`.
- Force local branch deletion uses `git branch -D`.
- Model copy and Git client behavior are covered by tests.
- `swift test`, the app verification script, and whitespace checks pass.
