# Spec 0285: Release Certificate Secret Validation

## Intent

Catch invalid Developer ID `.p12` exports before uploading release secrets to the
protected GitHub environment.

## Requirements

- Extend `script/configure_github_release_secrets.sh --dry-run` and upload mode
  to validate that the configured `.p12` can be imported with
  `BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD`.
- Validate the import in a temporary keychain that is deleted before the script
  exits.
- Confirm the imported keychain exposes the configured
  `BONSAI_CODESIGN_IDENTITY`.
- Do not print certificate bytes, passwords, Apple credentials, or any other
  secret values.
- Keep `--print-template` free of GitHub CLI and certificate validation
  requirements.

## Acceptance

- Dry run reports `Developer ID certificate: importable` when the `.p12` imports
  and exposes the configured identity.
- Upload mode performs the same validation before any `gh secret set` calls.
- `ReleaseScriptTests` prove dry run and upload paths validate the certificate
  with mocked `security` and still do not print secret values.
