# GitHub Release Setup

This guide configures the manual `Release` workflow. It is only needed for
maintainers who can publish Bonsai's notarized macOS artifact.

## Runner

The manual release workflow targets the Jarvis self-hosted runner with these
labels:

- `self-hosted`
- `macOS`
- `ARM64`
- `jarvis`

Jarvis should be online and available to the `devaryakjha/bonsai` repository
before starting the workflow. Regular pull request and push validation stays on
GitHub-hosted macOS runners and does not receive release credentials.

Check the configured runner without changing keychains or secrets:

```sh
./script/check_release_runner.sh
```

The script defaults to `ssh jarvis` and checks toolchain versions, visible
Developer ID Application identities, a harmless Developer ID signing smoke, and
the configured notarytool profile. Use `BONSAI_RELEASE_RUNNER_HOST` to point it
at another runner host.

## Protected Environment

Create a GitHub Actions environment named `release` and put the release secrets
there. Require reviewer approval for the environment before the workflow can
access secrets.

For `devaryakjha/bonsai`, the `release` environment has already been created
with `devaryakjha` as a required reviewer. The remaining setup is to add the
environment secrets below; repository-level release secrets should stay empty.

Check the GitHub-side release setup without printing secret values:

```sh
./script/package_release.sh --github-doctor
```

Maintainers can validate and upload the required environment secrets with:

```sh
export BONSAI_CODESIGN_IDENTITY="Developer ID Application: Example, Inc. (TEAMID)"
export BONSAI_DEVELOPER_ID_CERTIFICATE_PATH="/path/to/DeveloperID.p12"
export BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD="p12 export password"
export BONSAI_NOTARY_APPLE_ID="developer@example.com"
export BONSAI_NOTARY_APP_PASSWORD="app-specific password"
export BONSAI_NOTARY_TEAM_ID="TEAMID"

./script/configure_github_release_secrets.sh --dry-run
./script/configure_github_release_secrets.sh
```

The helper uploads only to the protected environment and runs
`./script/package_release.sh --github-doctor` after upload. It does not print
secret values.

The workflow consumes these secrets:

- `BONSAI_CODESIGN_IDENTITY`
- `BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64`
- `BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD`
- `BONSAI_NOTARY_APPLE_ID`
- `BONSAI_NOTARY_APP_PASSWORD`
- `BONSAI_NOTARY_TEAM_ID`

## Developer ID Certificate

Export the Developer ID Application certificate and private key from Keychain
Access as a password-protected `.p12` file. Do not commit this file.

Find the identity string:

```sh
security find-identity -p codesigning -v | grep "Developer ID Application"
```

Use the full quoted identity value as `BONSAI_CODESIGN_IDENTITY`, for example:

```text
Developer ID Application: Example, Inc. (TEAMID)
```

Create a single-line base64 value for the `.p12` secret:

```sh
base64 -i DeveloperID.p12 | tr -d '\n'
```

Store that output as `BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64`. Store the `.p12`
export password as `BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD`.

## Notarization Account

Create an app-specific password for the Apple ID that can notarize for the
Developer Team. Store:

- Apple ID email as `BONSAI_NOTARY_APPLE_ID`
- App-specific password as `BONSAI_NOTARY_APP_PASSWORD`
- Apple Developer Team ID as `BONSAI_NOTARY_TEAM_ID`

The workflow stores these values in a temporary keychain with:

```sh
xcrun notarytool store-credentials
```

The temporary profile name is `bonsai-ci-notary`; it is not a secret.
The workflow deletes the temporary keychain at the end of the job, including
failure paths.

## Workflow Run

Run the manual `Release` workflow from the audited commit. The workflow validates
source, imports the certificate, stores notarytool credentials, runs the release
doctor and credential preflight, builds the notarized archive, then uploads:

- `Bonsai.zip`
- `Bonsai.release.plist`

After downloading the artifact pair, verify it locally:

```sh
mkdir -p dist/release
cp Bonsai.zip Bonsai.release.plist dist/release/
./script/package_release.sh --verify-artifacts
```

The public release should attach both files.
