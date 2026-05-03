# Spec 0282: Release Secret Template

## Intent

Make the remaining Apple credential handoff less error-prone by giving
maintainers a command that prints the exact local environment variables needed
for the protected GitHub release environment.

## Requirements

- Add a no-network, no-secret mode to the GitHub release secret configurator.
- Print every required local export used by the secret uploader.
- Use placeholders rather than real-looking secret values.
- Include the dry-run, upload, and GitHub doctor commands after the exports.
- Document the template command in the release setup path.

## Acceptance

- `./script/configure_github_release_secrets.sh --print-template` exits zero
  without requiring `gh` or reading any private files.
- The template includes `BONSAI_CODESIGN_IDENTITY`,
  `BONSAI_DEVELOPER_ID_CERTIFICATE_PATH`,
  `BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD`, `BONSAI_NOTARY_APPLE_ID`,
  `BONSAI_NOTARY_APP_PASSWORD`, and `BONSAI_NOTARY_TEAM_ID`.
- Release script tests cover the template output.
