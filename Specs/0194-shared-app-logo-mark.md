# Spec 0194: Shared App Logo Mark

## Intent

Use the Bonsai worktree topology mark as the app's reusable in-product logo
surface instead of keeping the mark trapped in one empty state.

## Requirements

- Keep the topology mark vector-drawn in SwiftUI so it renders crisply at small
  and large sizes.
- Reuse the same mark in the empty repository state and the repository header.
- Keep the sidebar header calm: the mark replaces a generic system icon without
  adding another label or metadata row.
- Preserve the existing bundled SVG and `.icns` packaging path.

## Acceptance

- The empty repository view still shows the topology mark.
- The repository header uses the same topology mark.
- SwiftPM build and app verifier continue to pass.
