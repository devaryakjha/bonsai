# Spec 0095: Calm Repository Header Actions

## Objective

Keep the active repository header compact while preserving quick access to the
repository's filesystem location.

## Requirements

- The repository sidebar header shows the repository name and a concise state
  summary instead of the full filesystem path.
- The full repository path stays available through hover help.
- The repository sidebar context menu exposes Copy Path and Reveal in Finder.
- The Repository command menu exposes Copy Repository Path beside Reveal in
  Finder.
- Copy actions use the shared pasteboard helper.

## Acceptance

- The repository path is no longer always visible in the sidebar.
- Users can copy the active repository path from either the app menu or the
  repository sidebar row.
- `swift test`, the app verification script, and whitespace checks pass.
