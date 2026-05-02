# Spec 0096: Recent Repository Actions

## Objective

Make recent repositories manageable without adding persistent path clutter to the
sidebar.

## Requirements

- Recent repository rows keep their compact name-only presentation.
- Recent repository rows expose the full path through hover help.
- Recent repository context menus expose Copy Path and Reveal in Finder.
- Recent repository context menus expose Remove from Recents for stale entries.
- Recents management routes through `RepositoryStore`.

## Acceptance

- Users can copy or reveal a recent repository without first opening it.
- Users can remove a recent repository entry without deleting anything from
  disk.
- `swift test`, the app verification script, and whitespace checks pass.
