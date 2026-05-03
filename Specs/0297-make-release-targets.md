# Spec 0297: Make Release Targets

## Intent

Maintainer-facing workflows should use stable `make` targets instead of asking
people to remember individual script paths and flags.

## Requirements

- Add a root `Makefile` that keeps scripts as implementation details.
- Cover development validation, performance smoke, app launch, release
  verification, credential checks, secret setup, Jarvis preflight, and manual
  release dispatch.
- Update CI and release workflows to call the same make targets used by humans.
- Keep secret-handling behavior unchanged; make targets must only delegate to
  the existing scripts.
- Document the make targets in maintainer-facing release docs.

## Acceptance

- `make validate-scripts`, `make test`, `make perf`, `make release-verify`,
  `make release-verify-archive`, and `make release-verify-artifacts` pass
  locally.
- `ReleaseScriptTests` assert that CI and release workflows use make targets for
  source validation and artifact verification.
