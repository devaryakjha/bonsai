# Spec 0109: Tracking Action Arrow Labels

## Objective

Keep branch tracking notation consistent across badges, toolbar actions, and
menu commands.

## Requirements

- Pull labels use `↓` with the behind count when the current branch is behind
  its upstream.
- Push labels use `↑` with the ahead count when the current branch is ahead of
  its upstream.
- Zero-count labels remain `Pull` and `Push`.
- Labels use the already-parsed tracking data from `GitRef`.
- Sidebar tracking badges, toolbar actions, and Repository menu commands follow
  the same notation.

## Acceptance

- Pull and push labels no longer render bare numeric counts.
- Ref model tests cover arrow-aware action labels.
- `swift test`, the app verification script, and whitespace checks pass.
