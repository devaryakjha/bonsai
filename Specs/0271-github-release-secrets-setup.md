# Spec 0271: GitHub Release Secrets Setup

## Intent

Document the exact GitHub secret setup needed for Bonsai's manual notarized
release workflow, while keeping certificates, passwords, and Apple account
secrets out of the repository.

## Requirements

- List every secret consumed by `.github/workflows/release.yml`.
- Explain how to create the protected `release` environment.
- Explain how to export and base64-encode a Developer ID `.p12` certificate
  without checking it into the repo.
- Explain how to find the `BONSAI_CODESIGN_IDENTITY` string.
- Explain how the notary Apple ID, app-specific password, and team ID are used.
- Include a short verification path after the workflow artifact is downloaded.

## Acceptance

- `Documentation/GitHubReleaseSetup.md` exists.
- `Documentation/ReleaseChecklist.md` links to it before the manual workflow.
- `Documentation/ReleasePackaging.md` points CI release setup readers to it.
