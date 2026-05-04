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
make validate
make run-verify
make release-verify
make release-verify-archive
make release-verify-artifacts
```

For interactive sidebar, resize, or scrolling checks, also run the local release
app sampler:

```sh
make perf-ui
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
make release-doctor
```

Validate that the machine has the correct public-distribution credentials:

```sh
make release-check-credentials
```

The identity must be a `Developer ID Application` certificate. Apple Development
or Apple Distribution identities are not enough for direct macOS distribution.

## 4. Build, Sign, Notarize

Create the notarized release artifact:

```sh
make release-notarize
```

Expected local outputs:

- `dist/release/Bonsai.app`
- `dist/release/Bonsai.dmg`
- `dist/release/Bonsai.release.plist`

Do not publish the ad-hoc artifact created by `--verify`.

The `--notarize` path staples the app, creates and notarizes
`dist/release/Bonsai.dmg`, then writes the manifest for that final DMG.

## 5. GitHub Release

- Follow `Documentation/GitHubReleaseSetup.md` when configuring GitHub Actions
  release credentials for the first time.
- Confirm the Jarvis runner machine is reachable and has the expected release
  workflow toolchain state. This command must exit zero before relying on the
  GitHub Actions release workflow:
  ```sh
  make release-runner-workflow
  ```
- If using runner-local signing credentials instead of GitHub environment
  secrets, also run the stricter credential preflight:
  ```sh
  make release-runner
  ```
- Confirm the protected environment, Jarvis runner, and required environment
  secret names:
  ```sh
  make release-github-doctor
  ```
- If configuring the secrets from a local Developer ID `.p12`, run the helper
  template and dry run before upload:
  ```sh
  make release-secret-template
  make release-secrets-dry-run
  make release-secrets-upload
  ```
- Configure the protected `release` environment with these secrets:
  `BONSAI_CODESIGN_IDENTITY`,
  `BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64`,
  `BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD`,
  `BONSAI_NOTARY_APPLE_ID`,
  `BONSAI_NOTARY_APP_PASSWORD`, and
  `BONSAI_NOTARY_TEAM_ID`.
- Run the manual `Release` workflow once with the default `dry_run` input before
  attempting a credentialed release. This exercises the Jarvis runner, source
  validation, release archive creation, artifact verification, and workflow
  artifact upload without entering the protected `release` environment, reading
  Apple signing secrets, or creating a draft GitHub Release.
  ```sh
  make release-dry-run
  ```
- Run the manual `Release` workflow if the artifact should be produced by
  GitHub Actions, with `dry_run` disabled for the public artifact. The workflow
  targets the Jarvis self-hosted macOS ARM64 runner, uploads the notarized
  artifact pair to the workflow run, and creates a draft GitHub Release tagged
  from the audited commit.
  ```sh
  make release
  ```
- If using a local notarization run instead of the workflow, tag the audited
  commit and attach `dist/release/Bonsai.dmg` plus
  `dist/release/Bonsai.release.plist` manually.
- Keep the GitHub Release as a draft until the downloaded assets pass the
  post-release checks below, then publish it.
- Include a concise summary of v0 parity coverage and known limitations.
- Link `Specs/0242-v0-parity-evidence.md` for parity evidence.
- Link `Documentation/ReleasePackaging.md` for build and notarization details.

## 6. Post-Release Check

- Download the uploaded DMG and manifest from the draft GitHub Release on a
  clean macOS account or machine.
- Put `Bonsai.dmg` and `Bonsai.release.plist` in `dist/release/`, then run
  `make release-verify-artifacts`.
- Open the downloaded DMG and confirm it shows `Bonsai.app` plus the
  Applications shortcut.
- Run `xcrun stapler validate Bonsai.dmg`.
- Open Bonsai from the downloaded artifact.
- Confirm Gatekeeper accepts the app.
- Open a local Git repository and verify history, working tree, and diff loading.
