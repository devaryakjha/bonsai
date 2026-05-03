# Spec 0283: Jarvis Release Dry Run

## Intent

Exercise the exact Jarvis self-hosted release workflow path before Apple
Developer ID and notarization secrets are configured.

## Requirements

- Add a manual `dry_run` input to the `Release` workflow.
- Default `dry_run` to enabled so accidental manual dispatches do not create
  draft GitHub releases or require Apple signing secrets.
- In dry-run mode, run the same source validation on Jarvis, build the
  credential-free release archive with `script/package_release.sh --verify-archive`,
  verify the generated artifact pair, and upload the artifact pair to the
  workflow run.
- In dry-run mode, skip release secret checks, temporary signing keychain
  creation, notarization credentials, Developer ID credential checks,
  notarized packaging, and draft GitHub Release creation.
- In non-dry-run mode, preserve the existing credentialed notarization and draft
  GitHub Release path.
- Document the dry-run workflow as the first Jarvis release-runner check.

## Acceptance

- `.github/workflows/release.yml` exposes `dry_run`, uses Jarvis in both modes,
  builds `--verify-archive` only for dry runs, and gates secret/notarization/
  draft-release steps to non-dry runs.
- `Documentation/GitHubReleaseSetup.md` and `Documentation/ReleaseChecklist.md`
  tell maintainers to run the default dry run before relying on the credentialed
  release path.
- `ReleaseScriptTests` cover the workflow wiring.
- `swift test`, `actionlint`, and the release artifact verifier pass.
