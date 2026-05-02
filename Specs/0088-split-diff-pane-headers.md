# Spec 0088: Split Diff Pane Headers

## Objective

Make split diff mode feel like a complete two-pane source viewer by keeping the
before/after labels attached to their panes instead of rendering them as a
separate fixed-width row.

## Requirements

- Split diff pane headers must live inside the same `NSSplitView` panes as the
  text views.
- Pane headers must stay aligned when the split divider is resized.
- Header labels remain compact, native, and non-interactive.
- Existing selectable text rendering, scroll synchronization, inline
  highlights, and gutters remain unchanged.

## Acceptance

- Dragging the split divider cannot desynchronize the headers from their text
  panes.
- Split diff mode still renders the before and after labels.
- `swift test`, the app verification script, and whitespace checks pass.
