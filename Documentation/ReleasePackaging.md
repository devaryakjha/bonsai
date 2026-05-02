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

The script submits the zip with `xcrun notarytool submit --wait`, staples the
ticket to the app bundle, and runs Gatekeeper assessment. A local `--verify`
run is not a substitute for this credentialed notarization path.

## Outputs

- `dist/release/Bonsai.app`
- `dist/release/Bonsai.zip` for `--archive` and `--notarize`

The `dist/` directory is ignored by Git.
