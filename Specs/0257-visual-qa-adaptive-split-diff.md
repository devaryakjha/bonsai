# Spec 0257: Visual QA Adaptive Split Diff

## Intent

Close the v0 visual QA gate for compact and wide main-window layouts, with
specific attention to split diff readability. Split mode should remain useful at
minimum app width instead of squeezing both panes into unreadable columns.

## Requirements

- Capture real app screenshots at compact and wide window sizes.
- Verify sidebar density, toolbar wrapping, sheet/header sizing, and split diff
  completeness from the running app.
- Preserve side-by-side split diff when the detail pane is wide enough.
- Stack split diff panes when the detail pane is too narrow for readable
  side-by-side review.
- Keep the layout change inside the split diff renderer instead of changing the
  user's selected diff mode.

## Acceptance

- Compact visual QA screenshot:
  `/tmp/bonsai-visual-qa/main-1120-adaptive-split-2.png`.
- Wide visual QA screenshot:
  `/tmp/bonsai-visual-qa/main-1440-adaptive-split-2.png`.
- Compact split mode stacks before/after panes.
- Wide split mode stays side-by-side.
- Unit coverage pins the readable side-by-side threshold.
- `swift test`, the app verifier, release packaging verifier, and whitespace
  checks pass.
