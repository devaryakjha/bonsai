# Spec 0266: Release Credential Handoff

## Intent

Make the remaining v0 distribution blocker actionable for maintainers without
weakening the audit: Bonsai must still require a real Developer ID Application
certificate and validated notarytool profile before a public macOS artifact can
be called complete.

## Requirements

- Document how to find the exact Developer ID Application identity string.
- Document how to create and validate the notarytool keychain profile.
- Keep Apple Development and Apple Distribution identities explicitly rejected
  for direct public macOS distribution.
- Keep secrets out of the repository. The docs must use placeholders and
  interactive prompts instead of checked-in credentials.
- Preserve the existing release gate:
  `./script/package_release.sh --check-credentials` must pass before
  `./script/package_release.sh --notarize`.

## Acceptance

- `Documentation/ReleasePackaging.md` includes credential setup commands.
- `Documentation/ReleaseChecklist.md` points release maintainers to the setup
  section before validating credentials.
- The docs distinguish local ad-hoc verification from public notarized
  distribution.
