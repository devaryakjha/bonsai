# Spec 0264: Notarized Archive Restapling

## Intent

Ensure the public release zip contains the stapled app bundle, not only the
pre-submission signed bundle.

## Requirements

- Keep the initial zip creation before `notarytool submit`, because notarization
  submits an archive.
- Staple and validate the accepted ticket on `Bonsai.app`.
- Recreate `dist/release/Bonsai.zip` after stapling so the published archive
  contains the stapled bundle.
- Keep the credential-free `--verify` path unchanged.

## Acceptance

- `script/package_release.sh --notarize` recreates the zip after stapling.
- Documentation explains that the final zip is rebuilt after stapling.
- `git diff --check`, shell syntax validation, and
  `./script/package_release.sh --verify` pass.
