# Spec 0265: Release Archive Validation

## Intent

Fail signed and notarized release modes when `dist/release/Bonsai.zip` is
malformed or does not contain the expected app bundle metadata.

## Requirements

- Validate that `Bonsai.zip` exists after archive creation.
- Inspect archive contents without modifying the staged app bundle.
- Confirm the archive contains `Bonsai.app/Contents/Info.plist`.
- Confirm the archived `Info.plist` preserves bundle identifier, package type,
  marketing version, and build number.
- Confirm the extracted app bundle still passes strict code signature
  verification.
- Apply validation to both `--archive` and `--notarize`.
- Add a credential-free archive verification mode so this path can run in CI.

## Acceptance

- `script/package_release.sh` validates archive contents after every
  `create_archive` call.
- `script/package_release.sh --verify-archive` builds an ad-hoc signed local
  archive and validates it.
- `script/package_release.sh --archive` enforces a Developer ID Application
  identity before creating a distributable archive.
- Release packaging documentation states that archive structure and bundle
  metadata are validated.
- `git diff --check`, shell syntax validation, and
  `./script/package_release.sh --verify` pass.
