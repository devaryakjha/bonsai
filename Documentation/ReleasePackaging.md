# Release Packaging

Bonsai is a SwiftPM macOS app. Development launches use
`script/build_and_run.sh`; release validation uses `script/package_release.sh`
so distribution checks do not depend on the debug run path.

## Local Verification

Run the credential-free release verifier:

```sh
script/package_release.sh --verify
```

This builds `Bonsai` with `swift build -c release`, stages
`dist/release/Bonsai.app`, copies the app icon and topology SVG mark into
`Contents/Resources`, writes `Info.plist`, ad-hoc signs the bundle, and verifies
the code signature. This proves the bundle is structurally signable without
requiring an Apple Developer account.

The package version defaults to the root `VERSION` file. The build number
defaults to `git rev-list --count HEAD`. Release automation may override either
value:

```sh
export BONSAI_VERSION="0.1.0"
export BONSAI_BUILD_NUMBER="42"
```

## Signed Archive

Set a Developer ID Application identity before creating a distributable archive:

```sh
export BONSAI_CODESIGN_IDENTITY="Developer ID Application: Example, Inc. (TEAMID)"
script/package_release.sh --archive
```

The script writes `dist/release/Bonsai.zip` using `ditto` after signing with the
provided identity, timestamp, and hardened runtime option.

## Notarization

Notarization requires a signed archive and an `xcrun notarytool` keychain
profile:

```sh
export BONSAI_CODESIGN_IDENTITY="Developer ID Application: Example, Inc. (TEAMID)"
export BONSAI_NOTARY_PROFILE="bonsai-notary"
script/package_release.sh --notarize
```

The script submits the zip with `xcrun notarytool submit --wait`, staples and
validates the ticket on the app bundle, runs Gatekeeper assessment, then
recreates `dist/release/Bonsai.zip` so the published archive contains the
stapled app. A local `--verify` run is not a substitute for this credentialed
notarization path.

You can validate the local signing identity and notarytool profile before
running the full packaging workflow:

```sh
script/package_release.sh --check-credentials
```

This mode requires `BONSAI_CODESIGN_IDENTITY` to name a `Developer ID
Application` certificate present in the login keychain, and validates
`BONSAI_NOTARY_PROFILE` with `xcrun notarytool history`.

## Outputs

- `dist/release/Bonsai.app`
- `dist/release/Bonsai.zip` for `--archive` and `--notarize`

The `dist/` directory is ignored by Git.
