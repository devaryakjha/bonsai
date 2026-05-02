# Spec 0250: Release Packaging Readiness

## Intent

Make Bonsai's macOS distribution gate explicit and repeatable from the
repository instead of relying on the development run script as a release proxy.

## Requirements

- Add a dedicated release packaging script separate from
  `script/build_and_run.sh`.
- Build the `Bonsai` executable in release configuration.
- Stage a valid `.app` bundle with `Contents/MacOS`, `Contents/Resources`, a
  complete `Info.plist`, `Bonsai.icns`, and the topology SVG mark.
- Support a credential-free verification path that ad-hoc signs the bundle and
  validates the resulting code signature.
- Support Developer ID signing when `BONSAI_CODESIGN_IDENTITY` is provided.
- Support notarization when both `BONSAI_CODESIGN_IDENTITY` and
  `BONSAI_NOTARY_PROFILE` are provided.
- Document the release modes, required environment variables, and validation
  commands for OSS contributors.

## Acceptance

- `script/package_release.sh --verify` builds and validates
  `dist/release/Bonsai.app` without requiring Apple credentials.
- `bash -n script/package_release.sh` passes.
- Release packaging documentation explains the credentialed signing and
  notarization path without claiming the local verifier notarizes the app.
- `swift test`, the app verifier, and whitespace checks pass.
