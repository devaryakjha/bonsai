# Jarvis CI Runner

## Intent

Bonsai's macOS validation should use the available Jarvis self-hosted runner
instead of spending GitHub-hosted macOS minutes. The app is native macOS-only,
and the release workflow already depends on Jarvis, so regular CI should use
the same runner class.

## Requirements

- Run the push and pull-request `CI` workflow on the Jarvis self-hosted macOS
  ARM64 runner.
- Keep the existing no-secret validation steps for contributor safety.
- Keep the manual release workflow on Jarvis for both dry-run and notarized
  release paths.
- Run the deterministic performance smoke in both CI and release source
  validation.
- Document that routine validation no longer uses GitHub-hosted macOS runners.

## Acceptance

- `.github/workflows/ci.yml` uses the `self-hosted`, `macOS`, `ARM64`, and
  `jarvis` runner labels.
- `.github/workflows/release.yml` source validation syntax-checks both
  performance scripts and runs `./script/perf_large_repo.sh`.
- README and GitHub release setup docs identify Jarvis as the normal validation
  runner.
