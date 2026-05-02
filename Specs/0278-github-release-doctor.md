# Spec 0278: GitHub Release Doctor

## Intent

Make the remaining GitHub release setup diagnosable with one non-mutating command
instead of scattered manual `gh` checks.

## Requirements

- Add a release script mode that checks GitHub release readiness without
  building, signing, notarizing, or printing secret values.
- Verify the protected `release` environment exists.
- Verify a required reviewer rule is configured.
- Verify the Jarvis self-hosted runner is online and has `self-hosted`,
  `macOS`, `ARM64`, and `jarvis` labels.
- Verify the six required Apple distribution secret names exist in the protected
  environment.
- Warn when those release secret names exist at repository scope instead of the
  protected environment.

## Acceptance

- `./script/package_release.sh --github-doctor` reports the remaining missing
  release secret names and exits non-zero until the environment is complete.
- `--github-doctor` is documented in README and release setup docs.
- Release script tests cover the mode with a mocked GitHub CLI.
- `swift test --filter ReleaseScriptTests`, `git diff --check`, and shell syntax
  validation pass.
