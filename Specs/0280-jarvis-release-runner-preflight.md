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
- Avoid changing keychains, storing credentials, uploading secrets, or building
  release artifacts.
- Include the script in shell syntax validation.
- Document the script in the release setup flow.

## Acceptance

- `./script/check_release_runner.sh` runs the preflight over SSH and reports
  whether the visible Developer ID identity is usable for signing.
- `./script/check_release_runner.sh --local` runs the same read-only checks on
  the current machine.
- `BONSAI_RELEASE_RUNNER_HOST` overrides the default SSH host.
- `BONSAI_NOTARY_PROFILE` overrides the checked notarytool profile.
- `bash -n script/check_release_runner.sh` passes locally and in CI.
