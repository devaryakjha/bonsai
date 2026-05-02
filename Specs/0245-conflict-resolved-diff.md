# Spec 0245: Conflict Resolved Diff

## Intent

Close the Fork release-note gap for diffs after a conflicted file is resolved
in an external merge tool. A conflicted status row should not fall back to a
blank or unsafe staged diff once the user edits the working-tree file.

## Requirements

- Render conflicted files through Git's unmerged-file diff modes:
  base, ours, and theirs compared with the working tree.
- Default to base versus working tree so the resolved result is visible without
  extra setup.
- Keep the comparison selector inside diff options; this is useful detail, not
  permanent chrome.
- Reuse the existing rich unified and split diff renderers so search, syntax
  highlighting, and parser safeguards stay consistent.
- Keep hunk stage, unstage, and discard controls hidden while the file remains
  conflicted; the user should mark the resolved file explicitly.

## Acceptance

- Command builder coverage pins the exact Git arguments.
- Integration coverage proves base, ours, and theirs comparisons after an
  external working-tree edit.
- `swift test`, the app verifier, and whitespace checks pass.
