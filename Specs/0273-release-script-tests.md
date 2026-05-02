# Spec 0273: Release Script Tests

## Intent

Cover release-script credential and artifact-verification guardrails in the
normal test suite so future release hardening does not rely only on manual shell
checks.

## Requirements

- Add XCTest coverage for `script/package_release.sh --check-credentials`
  rejecting non-Developer ID identities.
- Add XCTest coverage for `script/package_release.sh --doctor` reporting all
  configured-but-invalid credential state without mutating artifacts.
- Add XCTest coverage that the script help and implementation keep
  `--verify-artifacts`, manifest hash checks, and `BONSAI_NOTARY_KEYCHAIN`
  support wired.
- Add XCTest coverage that the manual GitHub release workflow verifies artifacts
  before upload, uploads both the zip and manifest, and cleans up the temporary
  keychain.
- Do not run release builds or notarization from `swift test`.

## Acceptance

- `swift test --filter ReleaseScriptTests` passes.
- Full validation still includes script syntax, workflow linting, artifact
  verification, and the blocked credential preflight.
