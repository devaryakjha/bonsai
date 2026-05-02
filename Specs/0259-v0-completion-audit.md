# Spec 0259: v0 Completion Audit

## Intent

Audit the current tree against the user-stated v0 goal before claiming Bonsai is
complete. This document separates implemented parity evidence from distribution
gates that still require credentials.

## Objective Restatement

Bonsai v0 must be a free, open-source, native macOS Git client named Bonsai with
practical 1:1 feature parity to Fork's current public macOS feature surface,
premium native desktop UX, a rich and performant diff viewer, spec-driven
development, regular checkpoint commits, and OSS-ready project structure.

## Prompt-to-Artifact Checklist

| Requirement | Concrete evidence | Status |
| --- | --- | --- |
| Project is named Bonsai | `Package.swift`, `README.md`, bundle metadata in `script/package_release.sh`, app branding tests | Covered |
| Free/open-source shape | `LICENSE`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, spec directory, release docs | Covered |
| Native macOS app | SwiftPM executable target in `Sources/Bonsai`, SwiftUI/AppKit views, app verifier | Covered |
| Use supplied topology logo | `Assets/AppIcon/bonsai-worktree-topology.svg`, README logo, bundle resource copy, About panel branding tests | Covered |
| Spec-driven development | `Specs/0001-product-spec.md` plus focused specs through this audit | Covered |
| Regular checkpoint commits | Recent commits include visual QA, keyboard navigation parity, performance smoke, code-agent parity, and release evidence updates | Covered |
| Fork v0 feature parity | `Specs/0242-v0-parity-evidence.md` maps product-spec and Fork 2.66 release-note surfaces to implementation/test evidence | Covered |
| Modern premium desktop UX | `Documentation/InterfaceStandards.md`, copy/a11y specs, compact/wide visual QA in `Specs/0257-visual-qa-adaptive-split-diff.md` | Covered with subjective visual QA evidence |
| Rich performant diff viewer | `Specs/0005-diff-engine.md`, split/unified AppKit renderers, diff algorithm controls, large-diff bounds, performance smoke in `Specs/0256-large-repository-performance-pass.md` | Covered |
| Current public Fork release-note refresh | `Specs/0242-v0-parity-evidence.md` records `https://fork.dev/releasenotes` showing Fork 2.66 dated 10 Apr 2026 | Covered |
| Local build/test validation | `swift test`, `git diff --check`, app verifier, release package verifier, archive verifier, and artifact verifier were run after the latest implementation checkpoints | Covered |
| Public binary distribution | `script/package_release.sh --notarize` exists, but credentialed Developer ID signing and Apple notarization have not been run in this environment | Blocked |
| Hosted OSS validation | `.github/workflows/ci.yml` runs non-credentialed macOS validation, bundle verification, and archive verification for pushes and pull requests | Covered |
| OSS contribution intake | GitHub issue forms and pull request template keep bug, feature, security, and validation details structured | Covered |
| Public release handoff | `Documentation/ReleaseChecklist.md`, `Documentation/ReleasePackaging.md`, and `Documentation/GitHubReleaseSetup.md` define local release, GitHub release, secret setup, artifact, and post-release verification paths | Covered |
| Release version metadata | `VERSION` plus package scripts stamp `CFBundleShortVersionString` and `CFBundleVersion` into app bundles | Covered |
| Notarized archive contents | `script/package_release.sh --notarize` recreates `Bonsai.zip` after stapling so the published archive contains the stapled app | Covered |
| Release archive validation | `script/package_release.sh` extracts each release zip and validates archived bundle metadata after creation | Covered |
| Release credential diagnosis | `script/package_release.sh --doctor` reports Developer ID identity, configured signing identity, and notary profile readiness without mutating artifacts | Covered |
| Release artifact evidence | `script/package_release.sh` writes `dist/release/Bonsai.release.plist` for archive-producing modes with version, build, commit, zip hash, signature kind, team, and notarization state | Covered |
| Release artifact verification | `script/package_release.sh --verify-artifacts` validates the zip, manifest shape, archive name, byte size, and SHA-256 after packaging or download | Covered |
| Credentialed GitHub release path | `.github/workflows/release.yml` is manual-only, uses the protected `release` environment, imports the Developer ID certificate, stores notarytool credentials in a temporary keychain, runs `--notarize`, uploads zip plus manifest, and cleans up the temporary keychain | Covered pending configured secrets |

## Current Blocking Evidence

- `BONSAI_CODESIGN_IDENTITY` is not set in the current environment.
- `BONSAI_NOTARY_PROFILE` is not set in the current environment.
- `security find-identity -p codesigning -v` did not show a `Developer ID
  Application` identity; it showed Apple Development and Apple Distribution
  identities.
- `codesign -dvvv dist/release/Bonsai.app` reports the current local verifier
  artifact as ad-hoc signed.
- `spctl -a -vv -t exec dist/release/Bonsai.app` rejects the local ad-hoc
  artifact, which is expected for public distribution.
- `script/package_release.sh --doctor` reports no Developer ID identities,
  missing `BONSAI_CODESIGN_IDENTITY`, missing `BONSAI_NOTARY_PROFILE`, and
  `Distribution credentials: not ready`.
- `script/package_release.sh --check-credentials` fails before packaging with
  `BONSAI_CODESIGN_IDENTITY is required for --check-credentials`.

## Acceptance

- A credential preflight exists for the remaining distribution gate:
  `script/package_release.sh --check-credentials`.
- A read-only credential diagnostic exists:
  `script/package_release.sh --doctor`.
- A post-build artifact verifier exists:
  `script/package_release.sh --verify-artifacts`.
- A manual GitHub release workflow exists for maintainers after protected
  release secrets are configured.
- The audit does not mark the goal complete while Developer ID notarization is
  unverified.
