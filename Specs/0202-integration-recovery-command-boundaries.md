# Spec 0202: Integration Recovery Command Boundaries

## Intent

Git integrations and recovery operations are high-impact command surfaces. LFS
locks, signing config, in-progress operation recovery, bisect, git-flow, and
conflict resolution should have explicit argument builders like the rest of the
v0 Fork-parity command surface.

## Requirements

- Route Git LFS lock through a static argument builder.
- Route commit signing config through a static argument builder.
- Route merge, rebase, cherry-pick, and revert recovery actions through a static
  argument builder.
- Route bisect start, mark, and reset through static argument builders.
- Route git-flow init, start, and finish through static argument builders.
- Route conflict resolution through static argument builders for checkout and
  add commands.
- Preserve paths, branch names, flow names, and revisions as single arguments.

## Acceptance

- Command argument coverage proves LFS lock and signing config commands.
- Command argument coverage proves in-progress operation recovery commands.
- Command argument coverage proves bisect and git-flow commands.
- Command argument coverage proves conflict resolution command sequences.
- SwiftPM tests and the app verifier pass.
