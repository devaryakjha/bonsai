# Spec 0083: Inspection Row Copy Actions

## Objective

Make structured inspection sheets useful without forcing users to manually
select text when they need a commit identity.

## Requirements

- File-history rows expose a context action to copy the full commit hash.
- Blame rows expose a context action to copy the full commit hash.
- Existing Show commit actions must remain unchanged.
- Inspection sheet row density must stay compact.

## Acceptance

- Full hashes are copied, not shortened display hashes.
- Existing file-history and blame navigation remains unchanged.
- `swift test`, the app verification script, and whitespace checks pass.
