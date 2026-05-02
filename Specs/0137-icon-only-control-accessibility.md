# Spec 0137: Icon-only Control Accessibility

## Objective

Keep compact macOS controls professional and accessible by ensuring icon-only
buttons have explicit names without adding visible labels.

## Requirements

- Icon-only row, sheet, and sidebar controls must provide an accessibility label.
- Existing hover help remains in place for pointer users.
- Visible labels must not be added to compact rows solely for accessibility.
- The labels must name the action, not the icon.

## Acceptance

- Working-tree row controls name resolve, stage, and unstage actions.
- File-history and interactive-rebase icon controls name their actions.
- Repository setup and project rescan icon controls name their actions.
- `swift test`, the app verification script, and whitespace checks pass.
