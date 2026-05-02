# Spec 0262: v0 Release Checklist

## Intent

Give maintainers a single release handoff checklist for the first public Bonsai
build so packaging, notarization, evidence, and GitHub release steps are not
split across memory or ad-hoc notes.

## Requirements

- Add a release checklist document for the v0 public cut.
- Include pre-release evidence refresh steps.
- Include local non-credentialed validation commands.
- Include the credentialed Developer ID and notarization sequence.
- Include post-release GitHub artifact and announcement checks.
- Keep the checklist separate from the packaging reference so it can be followed
  top to bottom.

## Acceptance

- `Documentation/ReleaseChecklist.md` exists.
- The checklist references `Specs/0242-v0-parity-evidence.md` and
  `Specs/0259-v0-completion-audit.md`.
- The checklist includes `./script/package_release.sh --check-credentials` and
  `./script/package_release.sh --notarize`.
- README points release maintainers to the checklist.
- `git diff --check` passes.
