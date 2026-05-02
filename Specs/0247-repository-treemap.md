# Spec 0247: Repository Treemap

## Intent

Close the repository-treemap half of the current Fork release-note analytics
gap with an opt-in native visualization of tracked repository size. The feature
should make large folders/files obvious without adding permanent dashboard
chrome.

## Requirements

- Add a Repository Treemap action from the Repository command menu and the
  toolbar Tools > Repository menu.
- Present the treemap in a sheet, not in the sidebar or diff viewer.
- Use Git-backed tracked file sizes from `HEAD`.
- Aggregate file sizes by top-level directory or root file, sorted by size.
- Cap visible tiles and merge the tail into `Other` so the view stays legible.
- Render a real weighted rectangle treemap with a secondary detail list.
- Keep command construction in `GitClient`; views must not shell out directly.

## Acceptance

- Unit coverage pins the Git command, tree parsing, aggregation, and layout
  bounds.
- Integration coverage proves a real repository report aggregates expected
  top-level sizes.
- `swift test`, the app verifier, and whitespace checks pass.
