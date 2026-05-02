# Spec 0208: Tree Entry Copy

## Intent

Commit tree inspection should use professional product copy in visible details
instead of leaking Git plumbing terms such as `blob`.

## Requirements

- Present tree entry kinds as user-facing labels.
- Keep parser and identity behavior unchanged; only presentation copy changes.
- Continue showing commit hash and file mode in the detail header.

## Acceptance

- Tree entry kind presentation maps `blob` to `File`, `tree` to `Folder`,
  `commit` to `Submodule`, and unknown kinds to `Unknown`.
- Detail header uses the presentation label instead of the raw Git kind.
- SwiftPM build, tests, app verifier, and whitespace checks pass.
