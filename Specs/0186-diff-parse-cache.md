# Spec 0186: Diff Parse Cache

## Intent

Large diffs should not be reparsed every time SwiftUI asks for hunks, line
changes, or split rows. Bonsai already uses Git's diff engine and bounded
rendering; the store should cache parsed diff artifacts for the current diff
text.

## Requirements

- Parse hunks, line changes, and split diff rows when `diffText` changes.
- Keep the existing `diffHunks`, `diffLineChanges`, and `splitDiff` store API.
- Clear cached artifacts when the diff text is cleared.
- Keep raw diff text unchanged for copy-patch workflows.

## Acceptance

- Unit coverage proves derived artifacts update when `diffText` changes.
- Existing diff parser, split diff, and integration tests remain green.
- Validation gates pass.
