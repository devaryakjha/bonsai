# Spec 0140: Inspection Sheet Filtering

## Objective

Keep file history, line history, and blame sheets useful on large files without
showing more metadata by default.

## Requirements

- File history and line history sheets expose a compact search field in the
  sheet header.
- Blame sheets expose the same compact search field without changing the blame
  table columns.
- Empty search keeps the original ordering and full result set.
- Filtering is case-insensitive and matches commit hashes, subjects, authors,
  emails, paths, previous paths, status labels, line numbers, and line content.
- No-match states use short factual copy.

## Acceptance

- Unit tests cover file-history and blame filtering fields.
- Existing file history, blame, and commit-focus actions remain available from
  filtered rows.
