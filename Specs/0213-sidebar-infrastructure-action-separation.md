# Spec 0213: Sidebar Infrastructure Action Separation

## Intent

Keep infrastructure disclosures readable by separating existing entities from
their create/add commands.

## Requirements

- Worktree and remote create/add actions remain inside their relevant
  disclosure groups.
- When a worktree or remote list has existing rows, place a subtle divider
  before the inline action row.
- When the list is empty, show the inline action directly without a divider.
- Keep action rows compact, native, and free of extra metadata.

## Acceptance

- Existing worktree rows are visually separated from `Create worktree`.
- Existing remote rows are visually separated from `Add remote`.
- Empty worktree and remote disclosures still show their action without an
  empty separator.
- SwiftPM tests, app verifier, and whitespace checks pass.
