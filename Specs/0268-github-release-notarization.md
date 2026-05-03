# Spec 0268: GitHub Release Notarization

## Intent

Allow Bonsai maintainers to produce the v0 notarized macOS artifact from a
protected GitHub Actions environment once Apple distribution credentials are
available, without weakening local release validation.

## Requirements

- Add a manual GitHub Actions workflow for credentialed release packaging.
- Run the credentialed release workflow on the Jarvis self-hosted macOS ARM64
  runner instead of a GitHub-hosted runner.
- Keep regular pull request and push CI credential-free.
- Import the Developer ID certificate from repository or environment secrets
  into a temporary keychain.
- Store the notarytool credentials in that temporary keychain for the job.
- Run `./script/package_release.sh --doctor`, `--check-credentials`, and
  `--notarize`.
- Verify the final zip and manifest with
  `./script/package_release.sh --verify-artifacts`.
- Upload the final stapled `dist/release/Bonsai.zip` and
  `dist/release/Bonsai.release.plist` as workflow artifacts.
- Create a draft GitHub Release from the audited commit after artifact
  verification so maintainers can review assets before publishing.
- Keep credential names documented and avoid checking secrets into the
  repository.

## Acceptance

- `.github/workflows/release.yml` is manual-only.
- `.github/workflows/release.yml` targets the Jarvis self-hosted runner labels:
  `self-hosted`, `macOS`, `ARM64`, and `jarvis`.
- `script/package_release.sh` can validate and submit using an optional
  notarytool keychain path.
- The workflow verifies release artifacts before upload.
- The workflow creates a draft GitHub Release with the notarized zip and
  manifest after artifact verification.
- `Documentation/ReleaseChecklist.md` documents both local and GitHub release
  paths.
