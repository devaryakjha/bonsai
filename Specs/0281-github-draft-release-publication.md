# Spec 0281: GitHub Draft Release Publication

## Intent

Turn the credentialed Jarvis release workflow into a complete draft-release
handoff instead of leaving maintainers to manually move notarized artifacts from
workflow storage to a GitHub Release.

## Requirements

- Keep the `Release` workflow manual-only and protected by the `release`
  environment.
- Keep release packaging on the Jarvis self-hosted macOS ARM64 runner.
- Create a draft GitHub Release only after the notarized zip and manifest pass
  `./script/package_release.sh --verify-artifacts`.
- Attach both `dist/release/Bonsai.zip` and
  `dist/release/Bonsai.release.plist` to the draft release.
- Target the release tag at the audited workflow commit.
- Use the GitHub API from the workflow so Jarvis does not need the GitHub CLI
  installed for release publication.
- Avoid publishing directly; maintainers must still run post-release download
  and Gatekeeper checks before making the release public.

## Acceptance

- `.github/workflows/release.yml` has `contents: write` permission for release
  creation.
- `.github/workflows/release.yml` creates a draft GitHub Release after artifact
  verification and workflow artifact upload.
- `.github/workflows/release.yml` checks `curl` and `jq` availability and does
  not depend on `gh` for draft release creation.
- Release docs explain that the workflow creates a draft release, and that the
  downloaded assets still need local post-release verification before publish.
- `ReleaseScriptTests` cover the draft-release workflow wiring.
