# Contributing to Bonsai

Bonsai is a native macOS Git client built with SwiftPM. The v0 goal is practical
feature parity with Fork while keeping the interface calm, fast, and
professional.

## Development Workflow

- Start with a spec in `Specs/` for new features or meaningful behavior changes.
- Keep changes narrow and commit in small checkpoints.
- Prefer existing models, services, stores, and view patterns before adding new
  abstractions.
- Keep Git process execution inside `Sources/Bonsai/Services/GitClient.swift`
  or another focused service. Views should route actions through
  `RepositoryStore`.
- Follow `Documentation/InterfaceStandards.md` for product copy, control naming,
  status colors, and visual hierarchy.

## Validation

Run these before opening a pull request:

```sh
git diff --check
swift test
./script/build_and_run.sh --verify
./script/package_release.sh --verify
```

For UI-only documentation changes, `git diff --check` is the minimum gate. Run
the Swift validation commands when source, package, or script behavior changes.
GitHub Actions mirrors the non-credentialed gates on macOS: shell syntax,
`swift test`, and `./script/package_release.sh --verify`.

## Pull Requests

Keep pull requests focused on one spec or one closely related fix. Include:

- The spec or issue the change implements.
- A short summary of user-visible behavior.
- The validation commands run and their result.
- Screenshots or short recordings for meaningful UI changes.

## Project Structure

- `Sources/Bonsai/App`: app entry and command menu wiring.
- `Sources/Bonsai/Models`: Git and app domain values.
- `Sources/Bonsai/Services`: process, provider, and platform boundaries.
- `Sources/Bonsai/Stores`: state and action orchestration.
- `Sources/Bonsai/Views`: SwiftUI/AppKit-backed UI surfaces.
- `Sources/Bonsai/Support`: parsers, formatters, and small helpers.
- `Specs`: product and implementation specs.
- `Tests/BonsaiTests`: parser, service, and integration coverage.
