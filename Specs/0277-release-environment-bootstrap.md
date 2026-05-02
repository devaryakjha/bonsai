# Spec 0277: Release Environment Bootstrap

## Intent

Finish the non-secret GitHub setup required before maintainers add Apple
distribution credentials for the first public Bonsai release.

## Requirements

- Create a GitHub Actions environment named `release` for `devaryakjha/bonsai`.
- Require reviewer approval before the manual release workflow can access
  environment secrets.
- Keep repository-level release secrets empty so signing and notarization values
  are scoped to the protected environment.
- Update release handoff docs and the completion audit with the environment
  bootstrap state.

## Evidence

- `gh api repos/devaryakjha/bonsai/environments` reports the `release`
  environment with a required reviewer rule for `devaryakjha`.
- `gh secret list --repo devaryakjha/bonsai --env release` returns no secrets.
- `gh secret list --repo devaryakjha/bonsai` returns no repository secrets.

## Acceptance

- The remaining GitHub-side blocker is adding the six documented Apple
  distribution environment secrets.
- No secret values are committed or printed in documentation.
- `git diff --check` passes after the documentation update.
