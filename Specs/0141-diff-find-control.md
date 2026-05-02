# Spec 0141: Diff Find Control

## Objective

Make selected diffs searchable without adding permanent visual weight to the
diff surface.

## Requirements

- The diff header exposes an icon-only find control.
- Opening find shows a compact field and match count beside the existing diff
  controls.
- Closing find clears the query and removes search highlights.
- Unified and split diff renderers highlight case-insensitive matches.
- Match highlighting is bounded by the diff render policy so very large diffs
  keep rendering predictably.
- Empty queries do not alter the diff view.

## Acceptance

- Unit tests cover case-insensitive diff search, empty queries, and no-match
  labels.
- Existing diff view mode, algorithm selection, copy-patch, hunk, and line
  actions remain reachable.
