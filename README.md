<p align="center">
  <img src="Assets/AppIcon/bonsai-worktree-topology.svg#gh-light-mode-only" width="96" alt="Bonsai worktree topology logo">
  <img src="Assets/AppIcon/bonsai-worktree-topology-dark.svg#gh-dark-mode-only" width="96" alt="Bonsai worktree topology logo">
</p>

<h1 align="center">Bonsai</h1>

<p align="center">
  A native macOS Git client, built in the open as a free alternative to Fork.
</p>

<p align="center">
  <a href="#status">Status</a>
  ·
  <a href="#install">Install</a>
  ·
  <a href="#highlights">Highlights</a>
  ·
  <a href="#build">Build</a>
  ·
  <a href="CONTRIBUTING.md">Contributing</a>
</p>

<p align="center">
  <img src="Docs/Images/bonsai-preview-light.jpg#gh-light-mode-only" alt="Bonsai product screenshot showing history, split diff, and repository sidebar">
  <img src="Docs/Images/bonsai-preview-dark.jpg#gh-dark-mode-only" alt="Bonsai product screenshot showing history, split diff, and repository sidebar">
</p>

## Status

Bonsai is under highly active development. The v0 app surface is implemented,
and the first GitHub release contains a Developer ID signed and notarized macOS
archive.

The v0 goal is practical feature parity with Fork's public macOS feature set:
repository management, commit history, staging, rich unified and split diffs,
branch/tag/remote workflows, stashes, merge/rebase/cherry-pick/revert,
submodules, reflog recovery, file history, blame, conflict assistance, Git-flow,
Git LFS, GPG signing, and provider notifications.

## Install

Download the latest notarized macOS disk image from
[GitHub Releases](https://github.com/devaryakjha/bonsai/releases/latest).
Open the DMG, then drag `Bonsai.app` to the Applications shortcut.

For `v0.1.0`, the released assets are:

- [`Bonsai.dmg`](https://github.com/devaryakjha/bonsai/releases/download/v0.1.0/Bonsai.dmg)
- [`Bonsai.release.plist`](https://github.com/devaryakjha/bonsai/releases/download/v0.1.0/Bonsai.release.plist)

The release manifest records the build number, source commit, archive size,
SHA-256, signing kind, team identifier, and notarization state.

## Highlights

- Native SwiftUI macOS app, packaged from SwiftPM.
- Split and unified diff views with Git diff algorithm controls.
- Commit history with graph lanes, search, changed-file inspection, and revision
  actions.
- Working tree staging, unstaging, patch copy, discard, ignore, and conflict
  flows.
- Branches, tags, remotes, worktrees, submodules, stashes, Git LFS, and GitHub
  repository/notification workflows.
- Spec-driven development: every meaningful feature lands with a focused spec
  in `Specs/`.

## Build

Requirements:

- macOS 14 or newer
- Xcode command line tools
- Swift 5.9 or newer

Build and launch Bonsai:

```sh
make run
```

Build, launch, and verify that the app process is running:

```sh
make run-verify
```

Build and validate a release-style app bundle without Apple credentials:

```sh
make release-verify
```

Export the fallback `.icns` from the canonical Icon Composer document:

```sh
make app-icon
```

Run the large repository performance smoke:

```sh
make perf
```

Check local distribution credential readiness:

```sh
make release-doctor
make release-check-credentials
make release-github-doctor
make release-secret-template
make release-secrets-dry-run
make release-runner-workflow
make release-runner
```

The credential checks are expected to fail on machines without a Developer ID
Application certificate and a valid notarytool profile. The workflow runner
check only verifies the no-secret Jarvis toolchain required by GitHub Actions.
Maintainer release setup is documented in `Documentation/ReleaseChecklist.md`,
`Documentation/ReleasePackaging.md`, and `Documentation/GitHubReleaseSetup.md`.
The manual GitHub `Release` workflow defaults to a Jarvis dry run that builds
and verifies the credential-free archive without entering the protected release
environment or reading Apple release secrets.

Run the standard validation gates before submitting changes:

```sh
make validate
make run-verify
make release-verify
make release-verify-archive
make release-verify-artifacts
```

## Development

Bonsai is developed spec-first. Start with the relevant document in `Specs/`,
keep implementation slices small, and commit checkpoints as work lands.
Pull requests run on the Jarvis self-hosted macOS ARM64 runner for shell syntax,
`swift test`, the large-repository performance smoke, and the credential-free
release bundle, archive, and artifact verifiers.

Useful project paths:

- `Sources/Bonsai/App` - app entry point, commands, and scenes
- `Sources/Bonsai/Views` - native macOS SwiftUI interface
- `Sources/Bonsai/Stores` - observable app state and Git operation flow
- `Sources/Bonsai/Services` - Git, GitHub, and process execution services
- `Sources/Bonsai/Support` - parsers, rendering helpers, launchers, and policies
- `Tests/BonsaiTests` - focused parser, command, workflow, and integration tests
- `Documentation/ReleasePackaging.md` - release packaging, signing, notarization,
  and artifact verification workflow
- `Documentation/ReleaseChecklist.md` - first public release checklist
- `VERSION` - bundle marketing version used by package scripts

## Contributing

Contributions are welcome. Please read
`CONTRIBUTING.md` before opening a pull request, and keep UI changes aligned with
the interface standards and existing macOS conventions.

## Security

See `SECURITY.md` for supported versions and vulnerability reporting guidance.

## License

MIT. See `LICENSE`.
