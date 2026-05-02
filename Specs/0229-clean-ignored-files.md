# Spec 0229: Clean Ignored Files

## Objective

Let users remove ignored files from Bonsai after explicitly opting into ignored
file visibility.

## Requirements

- Keep ignored rows passive; do not add row-level clean or discard actions.
- Expose cleaning as a menu-based destructive action.
- Require explicit confirmation before removing ignored files.
- Enable the action only when ignored files are visible and present.
- Remove ignored files and directories through `git clean -f -X -d --`.
- Preserve staged, unstaged, untracked, and conflicted working-tree behavior.

## Acceptance

- Command argument coverage proves ignored cleaning uses `git clean -f -X -d`.
- Integration coverage proves ignored files are removed while untracked files
  remain.
- Existing ignored-file visibility behavior remains covered.
- `swift test`, the app verifier, and whitespace checks pass.
