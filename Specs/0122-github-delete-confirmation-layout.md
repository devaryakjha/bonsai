# Spec 0122: GitHub Delete Confirmation Layout

## Objective

Keep the GitHub delete confirmation sheet safe without rendering long
`owner/repository` text inside a wrapping label.

## Requirements

- The delete sheet still requires typing the exact `owner/name` target before
  enabling the destructive action.
- The visible confirmation label stays short and sentence-case.
- The target repository slug remains visible in a bounded, one-line row.
- Long owner or repository names truncate in the middle with hover help for the
  full value.
- The confirmation field keeps the full target as its placeholder.

## Acceptance

- The destructive confirmation behavior from Spec 0080 is unchanged.
- Long GitHub repository targets cannot force label wrapping.
- The app verification script, `swift test`, and whitespace checks pass.
