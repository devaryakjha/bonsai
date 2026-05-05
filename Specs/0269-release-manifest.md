# Spec 0269: Release Manifest

## Intent

Attach machine-readable evidence to each release archive so maintainers can
audit which commit, version, build number, archive hash, and signing state
produced a public Bonsai artifact.

## Requirements

- Generate a release manifest for archive-producing packaging modes.
- Include app name, bundle identifier, version, build number, git commit,
  archive file name, archive byte size, archive SHA-256, signing identity,
  signature kind, team identifier, and whether the archive was notarized.
- Validate the manifest with native plist tooling before reporting success.
- Upload the manifest alongside the DMG from the manual GitHub release workflow.
- Do not generate a manifest for credential-only modes.

## Acceptance

- `./script/package_release.sh --verify-archive` writes and validates
  `dist/release/Bonsai.release.plist`.
- `./script/package_release.sh --notarize` writes the manifest after the final
  post-stapling archive is recreated.
- The GitHub `Release` workflow uploads both `Bonsai.dmg` and the manifest.
