# Spec 0251: Claude-Generated Commit Message

## Intent

Close the generated-commit-message portion of Fork's AI parity delta with an
opt-in Claude Code integration that keeps the user in control of the final
commit text.

## Requirements

- Add a commit composer action that generates a commit message from staged
  changes only.
- Use an installed `claude` executable instead of adding provider keys or
  network settings to Bonsai.
- Keep the action disabled while no staged changes are present or generation is
  already running.
- Feed Claude a bounded staged diff plus diffstat and request plain commit text.
- Replace the commit message draft with the generated output, but do not commit
  automatically.
- Surface missing Claude Code or generation failures through the existing
  command-result area.
- Keep the composer compact: use a standard icon button with tooltip and
  accessibility label.

## Acceptance

- The commit composer exposes an icon-only `Generate commit message` action.
- The generated prompt and output normalization are unit-tested.
- `Specs/0242-v0-parity-evidence.md` records that generated commit messages are
  covered while branch review remains open.
- `swift test`, the app verifier, release packaging verifier, and whitespace
  checks pass.
