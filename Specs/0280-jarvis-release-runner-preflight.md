# Spec 0280: Jarvis Release Runner Preflight

## Intent

Make Jarvis release-runner readiness inspectable without hand-written SSH
commands or accidental secret exposure.

## Requirements

- Add a read-only script that checks the configured release runner host.
- Default to `jarvis` while allowing a host override.
- Report the remote macOS, Xcode, and Swift versions.
- Report visible `Developer ID Application` identities without printing private
  key material.
- Run a harmless Developer ID signing smoke when an identity is visible.
- Check a notarytool keychain profile and classify locked-keychain and missing
  profile states.
- Add a no-secret workflow mode for GitHub Actions releases that import signing
  credentials from protected environment secrets into a temporary keychain.
- Workflow mode checks required host/toolchain commands without inspecting
  Developer ID identities or notarytool keychain profiles.
- Avoid changing keychains, storing credentials, uploading secrets, or building
  release artifacts.
- Exit non-zero when the checked runner cannot sign with Developer ID or cannot
  validate the configured notarytool profile.
- Include the script in shell syntax validation.
- Document the script in the release setup flow.

## Acceptance

- `./script/check_release_runner.sh` runs the preflight over SSH and reports
  whether the visible Developer ID identity is usable for signing.
- The script prints `Release runner: ready` only when signing and notary checks
  both pass; otherwise it prints `Release runner: not ready` and exits non-zero.
- `./script/check_release_runner.sh --local` runs the same read-only checks on
  the current machine.
- `./script/check_release_runner.sh --workflow` runs the no-secret workflow
  preflight over SSH and prints `Release workflow runner: ready` when Jarvis has
  the required toolchain.
- `./script/check_release_runner.sh --workflow-local` runs the no-secret
  workflow preflight on the current machine.
- `BONSAI_RELEASE_RUNNER_HOST` overrides the default SSH host.
- `BONSAI_NOTARY_PROFILE` overrides the checked notarytool profile.
- `bash -n script/check_release_runner.sh` passes locally and in CI.
