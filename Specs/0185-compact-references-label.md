# Spec 0185: Compact References Label

## Intent

The sidebar disclosure for remote branches and tags should not risk wrapping in
compact windows. The visible label can be shorter while preserving the exact
meaning in hover help.

## Requirements

- Rename the visible `Remote branches and tags` disclosure to `References`.
- Preserve the combined count for remote branches and tags.
- Add hover help that spells out `Remote branches and tags`.
- Do not move or remove any reference actions.

## Acceptance

- The references disclosure has a compact visible label.
- Existing reference rows and context menus remain unchanged.
- Validation gates pass.
