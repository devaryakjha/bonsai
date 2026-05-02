# Spec 0195: Compact Hunk Action Strip

## Intent

Keep partial staging reachable without turning large diffs into a row of
repeated hunk buttons.

## Requirements

- Preserve direct hunk action for single-hunk diffs.
- Collapse multi-hunk action selection into one compact menu.
- Keep line staging, line history, and discard actions opt-in through menus.
- Preserve existing hunk, line, history, and discard command routing.
- Avoid adding visible explanatory copy to the diff surface.

## Acceptance

- Single-hunk diffs expose one direct hunk action.
- Multi-hunk diffs expose one hunk menu instead of one button per hunk.
- Line and discard actions remain available.
- SwiftPM build and app verifier pass.
