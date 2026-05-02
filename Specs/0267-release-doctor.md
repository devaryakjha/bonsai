# Spec 0267: Release Doctor

## Intent

Give maintainers one read-only command that reports why a machine cannot create
the v0 public macOS artifact yet. The strict release gates should remain strict,
but diagnosis should not stop at the first missing environment variable.

## Requirements

- Add a read-only `script/package_release.sh --doctor` mode.
- Report the resolved release version and build number.
- Report whether any Developer ID Application identities are visible in the
  codesigning keychain search.
- Report whether `BONSAI_CODESIGN_IDENTITY` is set, has the required identity
  prefix, and is present in the keychain.
- Report whether `BONSAI_NOTARY_PROFILE` is set and whether notarytool can
  validate it when set.
- Return a non-zero exit status when public distribution credentials are not
  ready.
- Do not build, sign, submit, staple, or mutate artifacts from doctor mode.
- Do not print packaging-success copy for credential-only modes.

## Acceptance

- `./script/package_release.sh --doctor` surfaces all missing credential inputs
  in one run.
- `./script/package_release.sh --check-credentials` remains strict and still
  fails before packaging when credentials are incomplete.
- Packaging modes still print the packaged app path after creating or verifying
  a bundle.
