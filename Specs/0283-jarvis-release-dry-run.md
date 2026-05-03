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
- Keep dry-run mode outside the protected `release` environment so the no-secret
  runner check can execute without release approval.
- In dry-run mode, skip release secret checks, temporary signing keychain
  creation, notarization credentials, Developer ID credential checks,
  notarized packaging, and draft GitHub Release creation.
- In non-dry-run mode, preserve the existing credentialed notarization and draft
  GitHub Release path.
- Document the dry-run workflow as the first Jarvis release-runner check.

## Acceptance

- `.github/workflows/release.yml` exposes `dry_run`, uses Jarvis in both modes,
  builds `--verify-archive` only for dry runs, keeps dry runs outside the
  protected `release` environment, and keeps secret/notarization/draft-release
  steps inside the non-dry-run path.
- `Documentation/GitHubReleaseSetup.md` and `Documentation/ReleaseChecklist.md`
  tell maintainers to run the default dry run before relying on the credentialed
  release path.
- `ReleaseScriptTests` cover the workflow wiring.
- `swift test`, `actionlint`, and the release artifact verifier pass.

## Evidence

- GitHub `Release` dry run
  `https://github.com/devaryakjha/bonsai/actions/runs/25272626762` completed
  successfully for commit `25ce981447503686220923ae3208e28ff5923518`.
- The `Dry-run macOS artifact` job ran on Jarvis, completed source validation,
  including the deterministic large-repository performance smoke, built the
  dry-run archive, verified release artifacts, and uploaded the dry-run artifact
  pair.
- The `Notarized macOS artifact` job was skipped for the dry run.
- The uploaded dry-run `Bonsai.zip` and `Bonsai.release.plist` artifact pair was
  downloaded and verified locally with `./script/package_release.sh
  --verify-artifacts`.
