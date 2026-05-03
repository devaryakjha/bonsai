# Spec 0279: GitHub Release Secret Configurator

## Intent

Make the final GitHub release credential handoff less error-prone by giving
maintainers one local command that uploads Apple distribution credentials to the
protected `release` environment without printing secret values.

## Requirements

- Add a maintainer-only script for configuring GitHub Actions release secrets.
- Target the protected `release` environment by default, not repository-level
  secrets.
- Read the Developer ID `.p12` path and release credential values from
  environment variables.
- Print a copy-safe local environment template so maintainers do not need to
  transcribe secret variable names from docs.
- Base64-encode the `.p12` locally before upload.
- Validate required inputs before mutating GitHub secrets.
- Provide a dry-run mode that checks local inputs and the GitHub environment
  without uploading values.
- Avoid echoing certificate, password, Apple ID, app password, or Team ID
  values.
- Run the GitHub release doctor after upload so maintainers get immediate
  readiness feedback.

## Acceptance

- `script/configure_github_release_secrets.sh --dry-run` validates inputs and
  exits without calling `gh secret set`.
- `script/configure_github_release_secrets.sh --print-template` prints all
  required local exports with placeholders and does not read or upload secrets.
- `script/configure_github_release_secrets.sh` uploads all six required secret
  names to the protected environment via `gh secret set --env release`.
- CI shell syntax validation includes the new script.
- Release setup docs point maintainers to the helper and keep manual secret
  names documented.
- Tests cover dry-run behavior and environment-scoped upload behavior with a
  mocked GitHub CLI.
