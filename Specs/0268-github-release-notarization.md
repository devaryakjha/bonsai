# Spec 0268: GitHub Release Notarization

## Intent

Allow Bonsai maintainers to produce the v0 notarized macOS artifact from a
protected GitHub Actions environment once Apple distribution credentials are
available, without weakening local release validation.

## Requirements

- Add a manual GitHub Actions workflow for credentialed release packaging.
- Keep regular pull request and push CI credential-free.
- Import the Developer ID certificate from repository or environment secrets
  into a temporary keychain.
- Store the notarytool credentials in that temporary keychain for the job.
- Run `./script/package_release.sh --doctor`, `--check-credentials`, and
  `--notarize`.
- Upload the final stapled `dist/release/Bonsai.zip` as a workflow artifact.
- Keep credential names documented and avoid checking secrets into the
  repository.

## Acceptance

- `.github/workflows/release.yml` is manual-only.
- `script/package_release.sh` can validate and submit using an optional
  notarytool keychain path.
- `Documentation/ReleaseChecklist.md` documents both local and GitHub release
  paths.
