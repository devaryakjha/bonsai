# Spec 0276: OSS Docs Release State

## Intent

Keep public-facing Bonsai documentation aligned with the actual v0 state before
the repository is opened.

## Requirements

- README status must distinguish the implemented v0 app surface from the
  notarized public binary now attached to GitHub Releases.
- README must expose the GitHub Releases installation path and the current
  `Bonsai.zip` plus `Bonsai.release.plist` asset pair.
- README build instructions must expose the credential doctor and credential
  preflight so maintainers can diagnose distribution readiness.
- Contributor and pull request validation docs must include the archive and
  artifact verifiers that CI runs.
- The product spec must not describe implemented repository and history surfaces
  as placeholders.
- Release setup docs must describe the current protected environment as
  configured while still keeping secret names and credential handoff paths
  documented for future maintainers.

## Acceptance

- Public docs no longer imply clone setup or history graph lanes are only
  placeholders.
- Release state is visible from README without leaking secrets.
- The published binary installation path is visible from README.
- `git diff --check` passes after the documentation update.
