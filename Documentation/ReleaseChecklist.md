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
```

For diff performance-sensitive changes, also run:

```sh
./script/perf_large_repo.sh
```

## 3. Distribution Credentials

Validate that the machine has the correct public-distribution credentials:

```sh
export BONSAI_CODESIGN_IDENTITY="Developer ID Application: Example, Inc. (TEAMID)"
export BONSAI_NOTARY_PROFILE="bonsai-notary"
export BONSAI_VERSION="$(tr -d '[:space:]' < VERSION)"
export BONSAI_BUILD_NUMBER="$(git rev-list --count HEAD)"
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

Do not publish the ad-hoc artifact created by `--verify`.

The `--notarize` path rebuilds `dist/release/Bonsai.zip` after stapling; upload
that final zip.

## 5. GitHub Release

- Tag the release from the audited commit.
- Attach `dist/release/Bonsai.zip`.
- Include a concise summary of v0 parity coverage and known limitations.
- Link `Specs/0242-v0-parity-evidence.md` for parity evidence.
- Link `Documentation/ReleasePackaging.md` for build and notarization details.

## 6. Post-Release Check

- Download the uploaded zip on a clean macOS account or machine.
- Open Bonsai from the downloaded artifact.
- Confirm Gatekeeper accepts the app.
- Open a local Git repository and verify history, working tree, and diff loading.
