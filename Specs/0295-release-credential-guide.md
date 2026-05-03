# Release Credential Guide

## Intent

The final v0 blocker is private Apple release credential setup. Maintainers who
have never shipped a direct-distribution Mac app should be able to derive each
required `BONSAI_*` value from Apple Developer, Keychain Access, and the local
certificate export flow without guessing.

## Requirements

- Document where each release credential value comes from.
- Make clear that the `.p12` export password is chosen locally by the
  maintainer during export.
- Make clear that the helper derives and uploads
  `BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64`; maintainers should provide the
  `.p12` path, not manually paste base64.
- Warn that `Developer ID Application` is required, and `Apple Distribution` or
  `Apple Development` certificates are not substitutes.
- Include the validation and upload command sequence already enforced by the
  helper scripts.

## Acceptance

- `Documentation/GitHubReleaseSetup.md` has a value-by-value table.
- The Developer ID certificate section explains certificate creation, Keychain
  installation, `.p12` export, identity lookup, and Team ID discovery.
- The notarization section explains Apple ID, app-specific password, and Team
  ID inputs.
