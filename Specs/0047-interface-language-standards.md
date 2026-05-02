# Spec 0047: Interface Language Standards

## Objective

Make Bonsai's UI copy and control naming consistent, professional, and aligned
with native macOS developer tools across every future feature pass.

## Requirements

- Add a project-level interface standard for UI copy, control naming, optional
  metadata, and compact control behavior.
- Keep product UI language precise and Git-native.
- Treat optional and destructive actions as opt-in unless they are the primary
  decision for the current surface.
- Require visible labels to fit their controls without wrapping or overlap.
- Preserve tooltip and accessibility coverage when visible copy is shortened.

## Acceptance

- New and changed UI surfaces can be reviewed against a written rule set.
- The current working-tree cleanup follows the rule set for copy, hierarchy, and
  optional controls.
- The rule set is referenced from `AGENTS.md` so future implementation passes
  inherit it.
