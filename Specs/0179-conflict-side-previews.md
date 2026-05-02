# Spec 0179: Conflict Side Previews

## Intent

The conflict resolver should show the actual Git conflict sides instead of only
the raw working-tree file with conflict markers. This keeps the resolver useful
without adding more working-tree row chrome.

## Requirements

- Load conflict preview content through `GitClient`.
- Show previews for working tree, base, ours, and theirs.
- Keep the resolver sheet compact by switching sides with a segmented control.
- Preserve the existing actions: `Accept ours`, `Accept theirs`, and
  `Mark resolved`.
- Handle unavailable or non-UTF-8 stages with clear, factual fallback text.

## Acceptance

- A real merge conflict exposes base, ours, and theirs preview text from Git's
  index stages.
- Existing conflict resolution behavior still stages the chosen resolution.
- Validation gates pass.
