# Spec 0177: Diff whitespace modes

## Intent

Bonsai's diff viewer must let users suppress whitespace-only noise without
making the default diff header busier. This should match established Git client
behavior: show all changes by default, with opt-in controls for ignoring
whitespace changes when reviewing noisy patches.

## Requirements

- Preserve `Show whitespace` as the default diff behavior.
- Add opt-in diff modes for `Ignore whitespace changes` and `Ignore all whitespace`.
- Apply the selected mode to working tree, staged, commit, stash file, and copied
  stash patch diffs.
- Persist the selected mode across launches.
- Keep the control inside existing diff options/settings surfaces, not as a new
  always-visible toolbar element.

## Acceptance

- A whitespace-only working tree change is visible in the default mode.
- The same change produces an empty patch when `Ignore all whitespace` is active.
- Existing diff algorithm and split/unified controls continue to work unchanged.
