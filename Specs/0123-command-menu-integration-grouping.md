# Spec 0123: Command Menu Integration Grouping

## Objective

Keep the macOS Git command menu scannable by grouping provider and extension
commands the same way the toolbar Actions menu does.

## Requirements

- Move Git LFS commands into a `Git LFS` submenu.
- Move Git-flow commands into a `Git-flow` submenu.
- Move GitHub notification and repository commands into a `GitHub` submenu.
- Keep existing disabled states, keyboard-independent reachability, and command
  routing intact.
- Keep menu command copy in macOS title case.

## Acceptance

- The Git command menu has fewer flat top-level rows.
- Integration commands remain reachable from the menu bar.
- The app verification script, `swift test`, and whitespace checks pass.
