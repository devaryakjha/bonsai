# Spec 0284: Release Runner Workflow Preflight

## Intent

Separate Jarvis workflow readiness from runner-local signing credential
readiness. The GitHub release workflow imports Apple credentials from the
protected `release` environment into a temporary keychain, so the no-secret
runner preflight should not fail only because Jarvis' interactive login keychain
is locked over SSH.

## Requirements

- Preserve the existing `script/check_release_runner.sh` default behavior for
  runner-local release credentials: Developer ID signing smoke and notary profile
  validation remain strict.
- Add a workflow preflight mode that checks Jarvis can run the GitHub release
  workflow without reading Apple release secrets.
- Workflow preflight must verify the required host/toolchain commands are
  available: `sw_vers`, `xcodebuild`, `swift`, `git`, `curl`, `jq`, `codesign`,
  `xcrun`, `security`, `ditto`, `plutil`, `shasum`, and `stat`.
- Workflow preflight must print `Release workflow runner: ready` only when all
  no-secret runner checks pass.
- Document when maintainers should use the workflow preflight versus the
  runner-local credential preflight.

## Acceptance

- `./script/check_release_runner.sh --workflow` checks Jarvis over SSH without
  touching signing identities or notary profiles.
- `./script/check_release_runner.sh --workflow-local` runs the same no-secret
  checks on the current machine.
- Existing default and `--local` behavior still require Developer ID signing and
  notary profile checks.
- Release docs and checklist use `--workflow` for the GitHub Actions release
  path and reserve the strict preflight for runner-local credential diagnosis.
- `ReleaseScriptTests` cover the new mode wiring.

## Evidence

- `./script/check_release_runner.sh --workflow-local` passed on the current
  machine and printed `Release workflow runner: ready`.
- `./script/check_release_runner.sh --workflow` reached Jarvis over SSH,
  confirmed the required no-secret workflow commands including `curl`, `jq`, and
  `notarytool`, and printed `Release workflow runner: ready`.
- `swift test --filter
  ReleaseScriptTests/testReleaseScriptDocumentsAndChecksArtifactVerifier`
  passed after adding the mode wiring.
