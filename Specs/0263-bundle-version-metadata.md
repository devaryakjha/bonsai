# Spec 0263: Bundle Version Metadata

## Intent

Make Bonsai release artifacts carry explicit macOS bundle version metadata before
the first public cut.

## Requirements

- Add a tracked project version source.
- Stamp both development and release app bundles with
  `CFBundleShortVersionString`.
- Stamp both development and release app bundles with `CFBundleVersion`.
- Allow release automation to override version and build number through
  environment variables.
- Make release bundle validation fail when version metadata is absent.

## Acceptance

- `VERSION` exists at the repository root.
- `script/build_and_run.sh` writes version metadata to `Info.plist`.
- `script/package_release.sh` writes and validates version metadata.
- `Documentation/ReleasePackaging.md` documents version environment overrides.
- `Documentation/ReleaseChecklist.md` includes version confirmation before
  publishing.
- `./script/package_release.sh --verify` produces a bundle with both version
  fields.
