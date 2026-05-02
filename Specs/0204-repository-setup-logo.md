# Spec 0204: Repository Setup Logo

## Intent

Repository setup sheets should use the Bonsai worktree topology mark where the
branding helps orientation without adding extra copy.

## Requirements

- Reuse `BonsaiLogoMark` in clone and create repository setup sheets.
- Keep the sheet header compact, native, and single-line at the current sheet
  width.
- Do not add explanatory text or duplicate product naming.
- Preserve the existing SVG and `.icns` asset sources.

## Acceptance

- Clone and create repository setup sheets render the shared topology mark next
  to the sheet title.
- SwiftPM build, tests, app verifier, and whitespace checks pass.
