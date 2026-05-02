# Spec 0236: Tree Snapshot Local Actions

## Intent

Keep commit tree browser actions truthful. A tree entry belongs to the selected
commit snapshot, so local working-tree actions should only appear when that path
exists in the current checkout.

## Requirements

- Commit tree rows always keep copy path actions.
- Commit tree rows expose `Open` and `Reveal in Finder` only when the path exists
  in the selected repository's working tree.
- The existence check lives in testable support/store code, not inline view
  string manipulation.
- Existing tree navigation and blob preview behavior remain unchanged.

## Acceptance

- Unit coverage proves repository-relative path existence checks.
- `swift test`, the app verifier, and whitespace checks pass.
