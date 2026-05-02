# v0 Release Checklist

Use this checklist for the first public Bonsai release. `ReleasePackaging.md`
explains the packaging commands; this file defines the release sequence.

## 1. Refresh Evidence

- Re-check Fork's current macOS release notes and update
  `Specs/0242-v0-parity-evidence.md` if new public surfaces exist.
- Re-read `Specs/0259-v0-completion-audit.md` and make sure every non-credential
  gate is still covered by current artifacts.
- Confirm `VERSION` matches the public release version.
- Confirm the working tree is clean before creating release artifacts.

## 2. Local Validation

Run the same non-credentialed gates expected from contributors:

```sh
git diff --check
swift test
./script/build_and_run.sh --verify
./script/package_release.sh --verify
./script/package_release.sh --verify-archive
./script/package_release.sh --verify-artifacts
```

For diff performance-sensitive changes, also run:

```sh
./script/perf_large_repo.sh
```

## 3. Distribution Credentials

If this machine has not shipped Bonsai before, complete the credential setup in
`Documentation/ReleasePackaging.md` first.

Set the release credential environment:

```sh
export BONSAI_CODESIGN_IDENTITY="Developer ID Application: Example, Inc. (TEAMID)"
export BONSAI_NOTARY_PROFILE="bonsai-notary"
export BONSAI_VERSION="$(tr -d '[:space:]' < VERSION)"
export BONSAI_BUILD_NUMBER="$(git rev-list --count HEAD)"
```

Check the full local credential state:

```sh
./script/package_release.sh --doctor
```

Validate that the machine has the correct public-distribution credentials:

```sh
./script/package_release.sh --check-credentials
```

The identity must be a `Developer ID Application` certificate. Apple Development
or Apple Distribution identities are not enough for direct macOS distribution.

## 4. Build, Sign, Notarize

Create the notarized release artifact:

```sh
./script/package_release.sh --notarize
```

Expected local outputs:

- `dist/release/Bonsai.app`
- `dist/release/Bonsai.zip`
- `dist/release/Bonsai.release.plist`

Do not publish the ad-hoc artifact created by `--verify`.

The `--notarize` path rebuilds `dist/release/Bonsai.zip` after stapling; upload
that final zip.

## 5. GitHub Release

- Configure the protected `release` environment with these secrets:
  `BONSAI_CODESIGN_IDENTITY`,
  `BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64`,
  `BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD`,
  `BONSAI_NOTARY_APPLE_ID`,
  `BONSAI_NOTARY_APP_PASSWORD`, and
  `BONSAI_NOTARY_TEAM_ID`.
- Run the manual `Release` workflow if the artifact should be produced by
  GitHub Actions.
- Tag the release from the audited commit.
- Attach the notarized `dist/release/Bonsai.zip` and
  `dist/release/Bonsai.release.plist` from the local notarization run or from
  the `Release` workflow artifact.
- Include a concise summary of v0 parity coverage and known limitations.
- Link `Specs/0242-v0-parity-evidence.md` for parity evidence.
- Link `Documentation/ReleasePackaging.md` for build and notarization details.

## 6. Post-Release Check

- Download the uploaded zip on a clean macOS account or machine.
- Put `Bonsai.zip` and `Bonsai.release.plist` in `dist/release/`, then run
  `./script/package_release.sh --verify-artifacts`.
- Open Bonsai from the downloaded artifact.
- Confirm Gatekeeper accepts the app.
- Open a local Git repository and verify history, working tree, and diff loading.
