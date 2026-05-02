# Spec 0276: OSS Docs Release State

## Intent

Keep public-facing Bonsai documentation aligned with the actual v0 state before
the repository is opened.

## Requirements

- README status must distinguish the implemented v0 app surface from the still
  blocked notarized public binary.
- README build instructions must expose the credential doctor and credential
  preflight so maintainers can diagnose distribution readiness.
- Contributor and pull request validation docs must include the archive and
  artifact verifiers that CI runs.
- The product spec must not describe implemented repository and history surfaces
  as placeholders.

## Acceptance

- Public docs no longer imply clone setup or history graph lanes are only
  placeholders.
- Release credential blockers are visible from README without leaking secrets or
  claiming notarization is complete.
- `git diff --check` passes after the documentation update.
