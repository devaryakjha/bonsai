# Spec 0039: Git Bisect

## Objective

Add v0 Git bisect support as part of Bonsai's Fork feature-parity surface for
finding regressions from the desktop app.

## Requirements

- Detect whether the selected repository is currently in a Git bisect session.
- Show active bisect status in the sidebar with the current test revision,
  known bad revision, known-good count, and skipped count when available.
- Allow starting a bisect from the selected commit as the known bad revision and
  a user-entered known good revision.
- Allow marking the current checkout as good, bad, or skipped.
- Allow resetting the bisect session.
- Use Git's native `git bisect` commands instead of reimplementing bisect logic.

## Acceptance

- Integration tests exercise start, mark good, mark bad, skip, status
  detection, and reset against a real Git repository.
- Actions are available from the toolbar actions menu and the macOS Git command
  menu.
- Active bisect state is visible in the sidebar integrations section.
- `swift test` and the app verification script pass.
