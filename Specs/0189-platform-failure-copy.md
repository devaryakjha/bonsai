# Spec 0189: Platform Failure Copy

## Intent

Platform fallback errors should read like in-window product feedback, not menu
commands. File and Terminal launch failures are command results, so their titles
should use sentence case.

## Requirements

- Use sentence-case command-result titles for file-open failures.
- Use sentence-case command-result titles for Terminal launch failures.
- Keep the detailed output path unchanged so failures remain actionable.
- Keep menu and context-menu labels unchanged.

## Acceptance

- Unit coverage locks the shared platform failure titles.
- File-open and Terminal fallback paths use the shared copy policy.
- Validation gates pass.
