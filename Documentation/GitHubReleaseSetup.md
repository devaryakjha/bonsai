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
before starting the workflow. Regular pull request and push validation also runs
on Jarvis with the same labels, but it stays outside the protected `release`
environment and does not receive release credentials.

The release workflow uses `script/create_github_draft_release.sh`, backed by
`curl` and `jq`, to create the draft GitHub Release via the GitHub API. It does
not require the GitHub CLI to be installed on Jarvis.

Check the configured runner can execute the GitHub release workflow without
changing keychains or reading Apple release secrets:

```sh
make release-runner-workflow
```

The script defaults to `ssh jarvis` and checks the no-secret toolchain required
by the workflow, including Swift, Xcode, Git, `curl`, `jq`, `codesign`,
`notarytool`, and archive/plist utilities. Use `BONSAI_RELEASE_RUNNER_HOST` to
point it at another runner host.

For a runner-local release that uses identities and notary profiles already
stored on Jarvis instead of GitHub environment secrets, use the stricter
credential preflight:

```sh
make release-runner
```

The strict mode checks visible Developer ID Application identities, runs a
harmless Developer ID signing smoke, and validates the configured notarytool
profile. It exits non-zero until signing and notary checks both pass.

## Protected Environment

Create a GitHub Actions environment named `release` and put the release secrets
there. Require reviewer approval for the environment before the workflow can
access secrets.

For `devaryakjha/bonsai`, the `release` environment has already been created
with `devaryakjha` as a required reviewer, and the current environment secrets
have produced a signed and notarized `v0.1.0` release. Repository-level release
secrets should stay empty; keep release secrets scoped to the protected
environment.

Check the GitHub-side release setup without printing secret values:

```sh
make release-github-doctor
```

Maintainers can validate and upload the required environment secrets with:

```sh
make release-secret-template

export BONSAI_CODESIGN_IDENTITY="Developer ID Application: Example, Inc. (TEAMID)"
export BONSAI_DEVELOPER_ID_CERTIFICATE_PATH="/path/to/DeveloperID.p12"
export BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD="p12 export password"
export BONSAI_NOTARY_APPLE_ID="developer@example.com"
export BONSAI_NOTARY_APP_PASSWORD="app-specific password"
export BONSAI_NOTARY_TEAM_ID="TEAMID"

make release-secrets-dry-run
make release-secrets-upload
```

The helper uploads only to the protected environment and runs
`make release-github-doctor` after upload. It does not print
secret values. Both `--dry-run` and upload mode first import the configured
Developer ID `.p12` into a temporary keychain and confirm it exposes
`BONSAI_CODESIGN_IDENTITY`; the temporary keychain is deleted before the helper
exits.

## Getting the Credential Values

| Local value | Source |
| --- | --- |
| `BONSAI_CODESIGN_IDENTITY` | Full quoted `Developer ID Application: ... (TEAMID)` identity from the local keychain |
| `BONSAI_DEVELOPER_ID_CERTIFICATE_PATH` | Local password-protected `.p12` export containing the Developer ID Application certificate and private key |
| `BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD` | Password chosen locally when exporting that `.p12` |
| `BONSAI_NOTARY_APPLE_ID` | Apple ID email that can notarize for the Apple Developer team |
| `BONSAI_NOTARY_APP_PASSWORD` | App-specific password for that Apple ID |
| `BONSAI_NOTARY_TEAM_ID` | Apple Developer Team ID, usually the value in parentheses in the Developer ID identity |

`BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64` is a GitHub environment secret, but it
is not a local value you need to paste. `script/configure_github_release_secrets.sh`
derives it from `BONSAI_DEVELOPER_ID_CERTIFICATE_PATH` and uploads it without
printing the certificate contents.

The workflow consumes these secrets:

- `BONSAI_CODESIGN_IDENTITY`
- `BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64`
- `BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD`
- `BONSAI_NOTARY_APPLE_ID`
- `BONSAI_NOTARY_APP_PASSWORD`
- `BONSAI_NOTARY_TEAM_ID`

## Developer ID Certificate

Create a Developer ID Application certificate from the Apple Developer account:

1. Open Apple Developer account settings.
2. Go to Certificates, Identifiers & Profiles.
3. Open Certificates and create a new certificate.
4. Under Software, choose Developer ID, then Developer ID Application.
5. Upload a certificate signing request from Keychain Access.
6. Download the `.cer` file and double-click it to install it into the login
   keychain.

To create the certificate signing request in Keychain Access:

1. Open Certificate Assistant > Request a Certificate From a Certificate
   Authority.
2. Enter the Apple ID email.
3. Use a recognizable common name, such as `Bonsai Developer ID`.
4. Save the request to disk and upload the `.certSigningRequest` file to Apple.

The certificate must appear in Keychain Access under My Certificates with a
private key nested under it. `Apple Development` and `Apple Distribution`
certificates are not valid substitutes for this direct-distribution release
path.

Export the Developer ID Application certificate and private key from Keychain
Access as a password-protected `.p12` file:

1. In Keychain Access, select the Developer ID Application certificate in My
   Certificates.
2. Right-click and choose Export.
3. Save it outside the repository, for example
   `~/Desktop/BonsaiDeveloperID.p12`.
4. Set a strong export password and use that as
   `BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD`.

Do not commit the `.p12` file.

Find the identity string:

```sh
security find-identity -p codesigning -v | grep "Developer ID Application"
```

Use the full quoted identity value as `BONSAI_CODESIGN_IDENTITY`, for example:

```text
Developer ID Application: Example, Inc. (TEAMID)
```

Use the `.p12` path as `BONSAI_DEVELOPER_ID_CERTIFICATE_PATH`. The helper
converts that file to the `BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64` GitHub secret
for you.

The Team ID is the value in parentheses in the identity string. It is also
available from the Apple Developer account membership page.

## Notarization Account

Use the Apple ID that can notarize for the Apple Developer team. Create an
app-specific password from Apple Account security settings and label it clearly,
for example `Bonsai Notarization`.

Store:

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

Run the manual `Release` workflow from the audited commit first with its default
`dry_run` input enabled. The dry run targets Jarvis, validates source, builds the
credential-free archive with `make release-verify-archive`,
verifies the generated artifact pair, and uploads it to the workflow run. It
does not use the protected `release` environment, read release secrets, create a
signing keychain, notarize, or create a draft GitHub Release.

For a public release, run the same workflow again with `dry_run` disabled after
`make release-github-doctor` reports the protected environment
is ready. The credentialed run imports the certificate, stores notarytool
credentials, runs the release doctor and credential preflight, builds the
notarized archive, uploads the artifact pair to the workflow run, and creates a
draft GitHub Release tagged from the audited commit with:

- `Bonsai.dmg`
- `Bonsai.release.plist`

Keep the GitHub Release as a draft until the downloaded asset pair passes local
post-release verification.

After downloading the asset pair, verify it locally:

```sh
mkdir -p dist/release
cp Bonsai.dmg Bonsai.release.plist dist/release/
make release-verify-artifacts
```

If the release artifact passes local verification, publish the draft release:

```sh
gh release edit v0.1.0 --draft=false
```

For `v0.1.0`, the published release is:

```text
https://github.com/devaryakjha/bonsai/releases/tag/v0.1.0
```

The public release should attach both files.
