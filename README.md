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

Bonsai is under highly active development. The v0 app surface is implemented and
is being hardened for the first public release. Public binary distribution is
still pending Developer ID signing and Apple notarization credentials.

The v0 goal is practical feature parity with Fork's public macOS feature set:
repository management, commit history, staging, rich unified and split diffs,
branch/tag/remote workflows, stashes, merge/rebase/cherry-pick/revert,
submodules, reflog recovery, file history, blame, conflict assistance, Git-flow,
Git LFS, GPG signing, and provider notifications.

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
./script/build_and_run.sh
```

Build, launch, and verify that the app process is running:

```sh
./script/build_and_run.sh --verify
```

Build and validate a release-style app bundle without Apple credentials:

```sh
./script/package_release.sh --verify
```

Run the opt-in large repository performance smoke:

```sh
./script/perf_large_repo.sh
```

Check local distribution credential readiness:

```sh
./script/package_release.sh --doctor
./script/package_release.sh --check-credentials
./script/package_release.sh --github-doctor
```

The credential checks are expected to fail on machines without a Developer ID
Application certificate and a valid notarytool profile. Maintainer release setup
is documented in `Documentation/ReleaseChecklist.md`,
`Documentation/ReleasePackaging.md`, and `Documentation/GitHubReleaseSetup.md`.

Run the standard validation gates before submitting changes:

```sh
git diff --check
swift test
./script/build_and_run.sh --verify
./script/package_release.sh --verify
./script/package_release.sh --verify-archive
./script/package_release.sh --verify-artifacts
```

## Development

Bonsai is developed spec-first. Start with the relevant document in `Specs/`,
keep implementation slices small, and commit checkpoints as work lands.
Pull requests run macOS CI for shell syntax, `swift test`, and the
credential-free release bundle, archive, and artifact verifiers.

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
