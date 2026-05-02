# Spec 0274: Compact Surface Fit Guardrails

## Intent

Keep dense Git-client surfaces from regressing into wrapped labels, crowded
headers, or visually noisy sidebar rows as Bonsai grows toward v0 parity.

## Requirements

- Sidebar disclosure labels reserve stable trailing space for counts and keep
  titles on one line.
- Sidebar infrastructure, integration, and inline action rows truncate long
  names, paths, URLs, and status details instead of wrapping or expanding row
  height.
- Dense diff header controls use icon-only tool actions when the action is
  already named by tooltip and accessibility label.
- Diff find controls adapt to narrower header widths without dropping the core
  search field, navigation, display-mode picker, options menu, or patch copy
  action.

## Acceptance

- Sidebar rows continue to use one leading icon, one title line, and at most one
  default detail line.
- Diff options remain reachable and accessible after the visible label is
  shortened to an icon-only control.
- SwiftPM tests, the app verifier, and whitespace checks pass.
