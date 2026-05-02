# Spec 0260: OSS CI Validation

## Intent

Give Bonsai an open-source-ready hosted validation path so contributors and
maintainers do not depend only on local manual checks.

## Requirements

- Add a GitHub Actions workflow for pull requests and pushes to `main`.
- Run on macOS because Bonsai is a native macOS app and packaging depends on
  Apple tooling.
- Validate shell syntax for project scripts.
- Run the Swift test suite.
- Run the credential-free release packaging verifier.
- Run the credential-free release archive verifier.
- Avoid credentialed Developer ID signing and notarization in CI.

## Acceptance

- `.github/workflows/ci.yml` exists and is narrow enough for OSS contributors to
  understand.
- The workflow runs `bash -n` for `script/build_and_run.sh`,
  `script/package_release.sh`, and `script/perf_large_repo.sh`.
- The workflow runs `swift test`.
- The workflow runs `./script/package_release.sh --verify`.
- The workflow runs `./script/package_release.sh --verify-archive`.
- Contributing docs mention that CI mirrors the non-credentialed gates.
