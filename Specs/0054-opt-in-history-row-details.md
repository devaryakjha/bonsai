# Spec 0054: Opt-in History Row Details

## Objective

Make commit history easier to scan by showing one-line commit rows by default
and making author, time, and ref decoration details opt in.

## Requirements

- Commit history rows must default to one visible line.
- Author, relative date, and decoration chips must remain available through a
  user setting.
- Compact rows must keep commit subject, graph lane, and short hash visible.
- Hidden row metadata must remain available by hover help.
- Commit search behavior must not change.

## Acceptance

- A new setting controls whether commit row details are shown.
- Default history rows no longer show the second metadata line.
- `swift test`, the app verification script, and whitespace checks pass.
