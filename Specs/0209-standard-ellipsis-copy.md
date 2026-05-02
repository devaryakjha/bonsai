# Spec 0209: Standard Ellipsis Copy

## Intent

Keep Bonsai's visible command copy aligned with macOS conventions by using a
single ellipsis glyph for actions that open another step.

## Requirements

- Replace three-period ellipses in user-facing command labels with `…`.
- Keep action labels otherwise unchanged unless the wording itself is wrong.
- Use the same glyph for shortened preview text so truncation reads like native
  app copy.
- Preserve existing behavior, shortcuts, and command enablement.

## Acceptance

- Menus, toolbar menus, context menus, and in-view command buttons no longer
  render `...` in visible labels.
- Recent commit and GitHub notification previews still cap their visible length.
- SwiftPM tests, app verifier, and whitespace checks pass.
