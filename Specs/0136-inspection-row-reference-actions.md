# Spec 0136: Inspection Row Reference Actions

## Objective

Make blame and file-history inspection rows useful for desktop review workflows
without adding more always-visible metadata.

## Requirements

- Blame rows expose context actions for copying the full commit hash, line
  reference, and line content.
- File-history rows expose context actions for copying the full commit hash,
  subject, author email, and changed paths.
- Previous paths from renames/copies remain available when Git reports them.
- Existing Show commit actions remain unchanged.
- The inspection sheets do not add persistent visible controls for these
  optional details.

## Acceptance

- Blame line references use `path:line` with the final line number.
- File-history changed path copy values are stable, unique, and newline-separated.
- Existing file-history and blame navigation remains unchanged.
- `swift test`, the app verification script, and whitespace checks pass.
