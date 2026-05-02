# Spec 0058: Colored Change Status Badges

## Objective

Make Git change status indicators immediately meaningful by rendering `M`, `A`,
`D`, `R`, and related status codes with conventional semantic colors.

## Requirements

- Raw changed-file status indicators must render as badges, not neutral text.
- Added files use green, deleted files use red, modified/type-changed files use
  amber, renamed files use purple, copied files use blue, and conflicts use
  orange.
- Rename and copy scores such as `R100` and `C75` must normalize to `R` and `C`
  visually while retaining a helpful tooltip.
- Working tree rows, the detail header, the commit changed-file list, and
  file-history change pills must share the same status presentation.
- Badge sizing must be stable so rows do not shift between status types.

## Acceptance

- `M`, `A`, and `D` are visually distinguishable without reading surrounding
  text.
- Status mapping is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
