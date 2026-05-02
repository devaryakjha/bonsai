# Spec 0201: Sidebar Infrastructure Sections

## Intent

Repository infrastructure should not read as one dense details bucket. Worktrees,
remotes, and submodules are different Git concepts, so the sidebar should give
them separate scan targets while keeping their item lists opt-in.

## Requirements

- Keep repository metrics, integrations, and references in the existing Details
  section.
- Move Worktrees, Remotes, and Submodules into separate sidebar sections.
- Keep Worktrees and Remotes present even when empty so create/add actions stay
  discoverable.
- Show Submodules only when the repository has submodules.
- Keep each infrastructure item list collapsed by default and explicitly labeled
  with its category or empty state.
- Preserve existing context-menu actions for worktrees, remotes, and submodules.

## Acceptance

- The sidebar no longer presents infrastructure as a single generic Details
  stack.
- Collapsed infrastructure rows use compact labels such as `Linked worktrees`,
  `No configured remotes`, and `Repository submodules`.
- SwiftPM tests and the app verifier pass.
