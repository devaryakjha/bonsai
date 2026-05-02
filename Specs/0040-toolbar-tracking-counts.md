# Spec 0040: Toolbar Tracking Counts

## Objective

Expose current-branch ahead/behind context directly on the primary pull and
push actions, matching the quick-glance workflow expected from modern Git
clients.

## Requirements

- Pull and push toolbar labels must include the current branch's behind/ahead
  counts when those counts are non-zero.
- The Repository menu pull and push commands must use the same count-aware
  titles.
- Zero counts must keep the concise labels `Pull` and `Push`.
- The labels must use the already-parsed upstream tracking data rather than
  running extra Git commands.

## Acceptance

- Ref model tests cover count-aware pull and push labels.
- The main toolbar uses count-aware pull and push labels.
- The Repository command menu uses count-aware pull and push labels.
- `swift test` and the app verification script pass.
