# Spec 0255: Revision Conflict Preflight

## Intent

Close Fork's cherry-pick/revert conflict-readiness delta without adding a noisy
pre-action screen. The confirmation sheet should tell the user whether Git
expects conflicts before they run the mutation.

## Requirements

- Run a read-only Git preflight for cherry-pick and revert requests.
- Use Git's merge machinery instead of parsing patches by hand.
- Show a compact status in the existing revision confirmation sheet.
- Keep merge and rebase confirmation behavior unchanged.
- Treat unavailable preflight as informational, not as a blocker.
- Do not mutate the working tree while checking readiness.

## Acceptance

- Cherry-pick confirmation shows checking, clean, conflict, or unavailable state.
- Revert uses the inverse three-way preflight.
- Unit coverage locks the Git arguments and user-facing readiness copy.
- Integration coverage proves clean and conflicting cherry-picks against a real
  repository.
- `Specs/0242-v0-parity-evidence.md` and
  `Specs/0243-fork-release-parity-refresh.md` record conflict readiness as
  covered.
- `swift test`, the app verifier, release packaging verifier, and whitespace
  checks pass.
