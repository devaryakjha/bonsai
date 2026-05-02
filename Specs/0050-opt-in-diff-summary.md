# Spec 0050: Opt-in Diff Summary

## Objective

Reduce detail-header visual load by making diff summary counts available on
demand instead of showing added/removed/hunk badges above every diff.

## Requirements

- Diff statistics must no longer render as always-visible header chips.
- Added, removed, hunk, and metadata-only information must remain available.
- Diff summary information should live in an existing relevant control rather
  than adding another permanent header element.
- The diff view mode, algorithm selector, and copy-patch action must remain
  directly reachable.

## Acceptance

- The detail header uses one row for the title and controls in normal diff
  review.
- `Diff options` exposes diff summary information when a diff is selected.
- `swift test`, the app verification script, and whitespace checks pass.
