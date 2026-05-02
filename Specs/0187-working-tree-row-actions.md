# Spec 0187: Working Tree Row Actions

## Intent

Working tree rows should stay calm by default while keeping common Git actions
close to the file they affect. Each row should expose one inline primary action
and keep secondary actions in the file-actions menu and context menu.

## Requirements

- Show exactly one inline primary action plus one file-actions menu for a
  working tree row.
- Use `Resolve conflict` as the primary action for conflicted rows.
- Use `Stage` or `Unstage` as the primary action for normal unstaged or staged
  rows.
- Keep stage, unstage, conflict resolution, copy, open, reveal, LFS, ignore, and
  discard actions reachable through existing menus.
- Preserve stable row height and avoid adding visible explanatory copy.

## Acceptance

- Unit coverage proves primary row action selection for staged, unstaged, and
  conflicted rows.
- Working tree row UI uses the policy instead of separate ad hoc inline buttons.
- Validation gates pass.
