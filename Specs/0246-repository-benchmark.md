# Spec 0246: Repository Benchmark

## Intent

Close the repository-benchmark half of the current Fork release-note analytics
gap with a native, opt-in report. The benchmark should help users understand
repository scale and Git responsiveness without adding persistent dashboard
chrome.

## Requirements

- Add a Repository Benchmark action from the Repository command menu and the
  toolbar Tools > Repository menu.
- Keep the report in a sheet instead of the main sidebar or diff area.
- Collect typed Git-backed counts for commits, refs, tracked files, working tree
  changes, loose objects, and packed objects.
- Measure the elapsed time for status, commit count, refs, tracked files, and
  object database reads.
- Keep command construction in `GitClient`; views must not shell out directly.
- Use concise, professional copy and native rows with secondary detail text.

## Acceptance

- Unit coverage pins benchmark Git arguments and object-stat parsing.
- Integration coverage proves a real repository report returns expected counts.
- `swift test`, the app verifier, and whitespace checks pass.
