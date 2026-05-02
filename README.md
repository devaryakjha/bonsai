# Bonsai

Bonsai is a native macOS Git client intended to be a free, open-source alternative
to Fork.

The v0 target is practical feature parity with Fork's public macOS surface:
repository management, commit history, working tree staging, side-by-side diffs,
branch/tag/remote workflows, stash management, merge/rebase/cherry-pick/revert,
submodules, reflog recovery, file history, blame, merge-conflict assistance,
Git-flow, Git LFS, GPG signing, and provider notifications.

## Development

Bonsai is built as a SwiftPM macOS app.

```sh
./script/build_and_run.sh
```

Use `./script/build_and_run.sh --verify` to build, launch, and confirm the app
process is running.

Run the standard validation gates before code changes are submitted:

```sh
git diff --check
swift test
./script/build_and_run.sh --verify
```

## Specs

Specs live in `Specs/` and are the source of truth for implementation order and
acceptance criteria.

## Contributing

See `CONTRIBUTING.md` for the local workflow, validation gates, and UI review
standards.

## Security

See `SECURITY.md` for supported versions and vulnerability reporting guidance.

## License

MIT. See `LICENSE`.
