# Spec 0272: Release Keychain Cleanup

## Intent

Make the manual GitHub release workflow clean up imported signing material even
when source validation, credential validation, notarization, or upload fails.

## Requirements

- Add an always-run cleanup step to `.github/workflows/release.yml`.
- Delete the temporary keychain created for the Developer ID certificate and
  notarytool profile when it exists.
- Do not fail the workflow from cleanup if the keychain was never created.
- Document that release credentials are imported into a temporary keychain and
  cleaned up at the end of the job.

## Acceptance

- `actionlint` accepts the workflow.
- The cleanup step uses the existing `BONSAI_NOTARY_KEYCHAIN` path.
- Release setup docs mention temporary-keychain cleanup.
