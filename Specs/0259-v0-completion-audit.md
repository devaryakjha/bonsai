# Spec 0259: v0 Completion Audit

## Intent

Audit the current tree against the user-stated v0 goal before claiming Bonsai is
complete. This document maps implemented parity, release packaging, and
post-release verification evidence to the explicit v0 requirements.

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
| Public binary distribution | GitHub `Release` run `25278300708` produced a Developer ID signed, notarized, stapled `Bonsai.zip`; the published GitHub Release `v0.1.0` attaches `Bonsai.zip` and `Bonsai.release.plist` | Covered |
| Hosted OSS validation | `.github/workflows/ci.yml` runs non-credentialed macOS validation, bundle verification, archive verification, and artifact verification for pushes and pull requests | Covered |
| OSS contribution intake | GitHub issue forms and pull request template keep bug, feature, security, and validation details structured | Covered |
| Public release handoff | `Documentation/ReleaseChecklist.md`, `Documentation/ReleasePackaging.md`, and `Documentation/GitHubReleaseSetup.md` define local release, GitHub release, secret setup, artifact, and post-release verification paths | Covered |
| Release version metadata | `VERSION` plus package scripts stamp `CFBundleShortVersionString` and `CFBundleVersion` into app bundles | Covered |
| Notarized archive contents | `script/package_release.sh --notarize` recreates `Bonsai.zip` after stapling so the published archive contains the stapled app | Covered |
| Release archive validation | `script/package_release.sh` extracts each release zip and validates archived bundle metadata after creation | Covered |
| Release credential diagnosis | `script/package_release.sh --doctor` reports Developer ID identity, configured signing identity, and notary profile readiness without mutating artifacts | Covered |
| GitHub release setup diagnosis | `script/package_release.sh --github-doctor` reports the protected environment, reviewer rule, Jarvis runner labels, required environment secret names, repository-level secret leakage, and no-secret remediation commands without printing secret values | Covered |
| GitHub release secret handoff | `script/configure_github_release_secrets.sh` validates local Apple release credential inputs, imports the Developer ID `.p12` into a temporary keychain to confirm it exposes the configured identity, uploads the six required secret names to the protected environment, and reruns the GitHub release doctor without printing secret values; `make release-github-doctor` reports ready | Covered |
| GitHub release secret template | `script/configure_github_release_secrets.sh --print-template` prints the required local release credential exports with placeholders and no GitHub CLI dependency | Covered |
| Jarvis release runner preflight | `script/check_release_runner.sh --workflow` checks Jarvis' no-secret GitHub Actions release toolchain and now exits zero with `Release workflow runner: ready`; strict `script/check_release_runner.sh` still checks runner-local Developer ID identities, signing smoke, and notary profile state without changing secrets or keychains | Covered |
| Jarvis release workflow dry run | The manual `Release` workflow defaults to a no-secret dry run on Jarvis outside the protected `release` environment, runs source validation, builds `--verify-archive`, verifies the artifact pair, and skips secret checks, notarization, and draft release creation; run `25278101378` passed | Covered |
| Release artifact evidence | `script/package_release.sh` writes `dist/release/Bonsai.release.plist` for archive-producing modes with version, build, commit, zip hash, signature kind, team, and notarization state | Covered |
| Release artifact verification | `script/package_release.sh --verify-artifacts` validates the zip, manifest shape, archive name, byte size, and SHA-256 after packaging or download | Covered |
| Release guardrail tests | `Tests/BonsaiTests/ReleaseScriptTests.swift` covers credential rejection, doctor output, artifact verifier wiring, manifest upload, draft release upload/cleanup, release secret template output, and temporary keychain cleanup wiring without running release builds or notarization | Covered |
| Credentialed GitHub release path | `.github/workflows/release.yml` is manual-only, targets Jarvis, uses the protected `release` environment, imports the Developer ID certificate, stores notarytool credentials in a temporary keychain, runs `--notarize`, uploads zip plus manifest, creates a draft GitHub Release from the audited commit, and cleans up the temporary keychain; run `25278300708` passed | Covered |

## Current Release Evidence

- GitHub repository visibility is public:
  `https://github.com/devaryakjha/bonsai`.
- GitHub push CI
  `https://github.com/devaryakjha/bonsai/actions/runs/25278268466` completed
  successfully on the Jarvis self-hosted macOS runner for commit
  `d817e8bb8d20f5126b93a712f0e784af2586847e`.
- GitHub `Release` dry run
  `https://github.com/devaryakjha/bonsai/actions/runs/25278101378` completed
  successfully on Jarvis for commit
  `67b4fc152c230a7ae34a3fa261bfc5c745826db1`.
- GitHub credentialed `Release` run
  `https://github.com/devaryakjha/bonsai/actions/runs/25278300708` completed
  successfully on Jarvis for commit
  `d817e8bb8d20f5126b93a712f0e784af2586847e`.
- The credentialed release run imported the Developer ID certificate into a
  temporary keychain, stored notarytool credentials, passed
  `make release-doctor` and `make release-check-credentials`, built the archive,
  received Apple notarization status `Accepted`, stapled the app, validated the
  staple, and passed Gatekeeper assessment with `source=Notarized Developer ID`.
- The credentialed release run uploaded workflow artifact `Bonsai-0.1.0-11`
  and created one GitHub Release for `v0.1.0` targeted at
  `d817e8bb8d20f5126b93a712f0e784af2586847e` with `Bonsai.zip` and
  `Bonsai.release.plist` attached.
- `v0.1.0` was published after post-download verification, and its stable
  asset URLs are
  `https://github.com/devaryakjha/bonsai/releases/download/v0.1.0/Bonsai.zip`
  and
  `https://github.com/devaryakjha/bonsai/releases/download/v0.1.0/Bonsai.release.plist`.
- The published release assets were downloaded with `gh release download
  v0.1.0`, matched the release asset SHA-256 digests, passed
  `make release-verify-artifacts`, and the extracted app passed
  `xcrun stapler validate` plus `spctl -a -vv -t exec`.
- The downloaded build `11` artifact pair was copied to `dist/release` and
  verified locally with `make release-verify-artifacts`.
- The downloaded `Bonsai.zip` was extracted locally and verified with
  `xcrun stapler validate` and `spctl -a -vv -t exec`.
- The downloaded manifest records `version=0.1.0`, `buildNumber=11`,
  `gitCommit=d817e8bb8d20f5126b93a712f0e784af2586847e`,
  `archiveSHA256=09af6c072ed0c2f5309dec2979cac2c477be7410834839fcf7f72e12a0a3e332`,
  `signatureKind=Developer ID`, `teamIdentifier=KZX5HZ32P9`, and
  `notarized=true`.
- The extracted app bundle contains `Contents/Resources/Bonsai.icns`,
  `Contents/Resources/Bonsai.icon/icon.json`, the Icon Composer light/dark SVG
  assets, and the topology SVG fallback.
- `make release-github-doctor` reports the `release` environment, required
  reviewer, Jarvis runner labels, all six protected environment secrets, and no
  repository-level release secret leakage as ready.

## Acceptance

- A credential preflight exists:
  `script/package_release.sh --check-credentials`.
- A read-only credential diagnostic exists:
  `script/package_release.sh --doctor`.
- A read-only GitHub release setup diagnostic exists:
  `script/package_release.sh --github-doctor`.
- A maintainer-only protected environment secret upload helper exists and
  validates the Developer ID `.p12` in a temporary keychain before upload:
  `script/configure_github_release_secrets.sh`.
- A no-secret release credential template exists:
  `script/configure_github_release_secrets.sh --print-template`.
- A read-only Jarvis release workflow preflight exists:
  `script/check_release_runner.sh --workflow`.
- A strict read-only Jarvis runner-local credential preflight exists:
  `script/check_release_runner.sh`.
- The manual Jarvis release workflow has a default dry run that exercises the
  self-hosted runner path without release-environment approval or Apple release
  secrets.
- A post-build artifact verifier exists:
  `script/package_release.sh --verify-artifacts`.
- Release guardrails are covered by `ReleaseScriptTests`.
- A manual GitHub release workflow and protected `release` environment exist,
  and the current protected release run produced a published GitHub Release with
  notarized macOS binaries attached.
