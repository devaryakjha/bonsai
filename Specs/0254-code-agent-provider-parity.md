# Spec 0254: Code Agent Provider Parity

## Intent

Close the Fork AI integration delta for both supported installed-agent CLIs:
Claude Code and Codex CLI. Keep AI optional, explicit, and user-triggered.

## Requirements

- Keep commit message generation and branch review opt-in.
- Offer provider choices for both actions: `Claude Code` and `Codex CLI`.
- Reuse the same bounded staged diff, branch diff, diffstat, base selection, and
  normalization rules across providers.
- Run Codex non-interactively with read-only sandboxing and no approval prompts.
- Surface missing provider executables through the existing command-result path.
- Do not commit, edit files, apply patches, or mutate repositories from either
  provider action.

## Acceptance

- The commit composer exposes provider choices from the sparkle menu.
- `Tools > Inspect > Review Current Branch` exposes provider choices.
- Unit coverage locks Claude and Codex CLI argument boundaries.
- `Specs/0242-v0-parity-evidence.md` and
  `Specs/0243-fork-release-parity-refresh.md` record the Codex AI delta as
  covered.
- `swift test`, the app verifier, release packaging verifier, and whitespace
  checks pass.
