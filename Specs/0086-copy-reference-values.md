# Spec 0086: Copy Reference Values

## Objective

Make branch and tag context menus useful for everyday Git workflows that need a
reference name or target commit outside Bonsai.

## Requirements

- Local branch context menus expose copy actions for the short branch name, full
  ref name, and target commit hash.
- Remote branch context menus expose copy actions for the short remote branch
  name, full ref name, and target commit hash.
- Tag context menus expose copy actions for the tag name, full ref name, and
  target object hash.
- Existing checkout, create, rename, upstream, and delete actions must remain
  unchanged.
- Copy actions must use the shared pasteboard helper.

## Acceptance

- Branch and tag names copy the displayed short name.
- Full ref copy actions copy the `refs/...` name.
- Hash copy actions copy the full parsed object name.
- `swift test`, the app verification script, and whitespace checks pass.
