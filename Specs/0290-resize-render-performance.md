# Resize Render Performance

## Intent

Window resizing and sidebar collapse must stay responsive even while a large diff
is visible. Layout invalidation must not re-scan, deep-compare, or re-render the
current patch unless the diff content or find query actually changed.

## Requirements

- Rich diff AppKit bridges use a cheap render revision when the store owns the
  diff content, avoiding full string or split-diff equality checks during
  SwiftUI layout updates.
- Diff summary and binary-diff state are cached with the parsed diff artifacts
  instead of being recomputed by header/body layout passes.
- Existing text-only previews that do not have a store revision keep their
  value-based fallback rendering behavior.

## Acceptance

- Store coverage proves diff revisions advance only when diff text changes and
  the cached summary stays in sync.
- Existing diff parse, split diff, and search behavior remains green.
- A local app build/verify succeeds after the resize hot-path cleanup.
