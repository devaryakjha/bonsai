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

To also create and validate a local test archive with an ad-hoc signature, run:

```sh
script/package_release.sh --verify-archive
```

The package version defaults to the root `VERSION` file. The build number
defaults to `git rev-list --count HEAD`. Release automation may override either
value:

```sh
export BONSAI_VERSION="0.1.0"
export BONSAI_BUILD_NUMBER="42"
```

## Credential Setup

Direct macOS distribution requires a Developer ID Application certificate. Use
the exact identity string reported by the keychain:

```sh
security find-identity -p codesigning -v | grep "Developer ID Application"
```

If that command prints nothing, create or install a Developer ID Application
certificate from the Apple Developer account before continuing. Apple
Development and Apple Distribution identities are not valid substitutes for this
release path.

Store notarization credentials in the keychain with `notarytool`. This keeps the
release script free of secrets:

```sh
xcrun notarytool store-credentials bonsai-notary \
  --apple-id "developer@example.com" \
  --team-id "TEAMID"
```

`notarytool` prompts for the app-specific password when `--password` is omitted.
Validate the stored profile before running a full release:

```sh
xcrun notarytool history --keychain-profile bonsai-notary
```

CI jobs may store the profile in a temporary keychain. In that case, export the
keychain path so the release script passes it to `notarytool`:

```sh
export BONSAI_NOTARY_KEYCHAIN="$RUNNER_TEMP/bonsai-signing.keychain-db"
```

## Signed Archive

Set a Developer ID Application identity before creating a distributable archive:

```sh
export BONSAI_CODESIGN_IDENTITY="Developer ID Application: Example, Inc. (TEAMID)"
script/package_release.sh --archive
```

The script writes `dist/release/Bonsai.zip` using `ditto` after signing with the
provided identity, timestamp, and hardened runtime option, then validates that
the archive contains `Bonsai.app` with the expected bundle identifier, package
type, marketing version, build number, and a strict-valid code signature.

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

For a read-only report that lists all missing credential inputs in one pass, run:

```sh
script/package_release.sh --doctor
```

Doctor mode does not build, sign, submit, staple, or rewrite artifacts. It
returns a non-zero status until Developer ID and notarytool credentials are
ready.

## Outputs

- `dist/release/Bonsai.app`
- `dist/release/Bonsai.zip` for `--verify-archive`, `--archive`, and
  `--notarize`

The `dist/` directory is ignored by Git.
