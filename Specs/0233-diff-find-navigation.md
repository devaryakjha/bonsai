# Spec 0233: Diff Find Navigation

## Intent

Make the diff find field actionable, not just informational, by letting users
move between highlighted matches from the compact diff header controls.

## Requirements

- Visible diff find controls expose icon-only previous and next match actions.
- Pressing Return in the find field moves to the next match.
- Navigation is disabled for empty queries and no-match states.
- Unified diff navigation selects and scrolls the next or previous rendered
  match, wrapping at document edges.
- Split diff navigation moves within the active pane first, then crosses to the
  other pane before wrapping.
- The added controls keep accessible labels and do not add permanent weight when
  find is hidden.

## Acceptance

- Unit coverage proves search navigation chooses forward, backward, wrapping,
  and non-wrapping ranges.
- Existing diff find labels, highlighting, display modes, and copy-patch actions
  remain available.
- SwiftPM tests, app verifier, and whitespace checks pass.
