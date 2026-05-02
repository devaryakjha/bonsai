# Spec 0207: Settings Label Fit

## Intent

Settings should follow Bonsai's interface standards: visible labels stay visible
and compact labels do not wrap. The diff algorithm row is especially important
because wrapped labels make the app feel unfinished.

## Requirements

- Keep every settings label visible rather than removing labels to solve fit.
- Use stable row geometry so labels such as `Algorithm` and `Commit row details`
  stay on one line.
- Give segmented diff controls enough horizontal room for their values.
- Avoid adding explanatory copy or dense metadata to settings.

## Acceptance

- Settings rows render with a fixed label column and no wrapping labels.
- Existing settings preferences keep the same keys and values.
- SwiftPM build, tests, app verifier, and whitespace checks pass.
