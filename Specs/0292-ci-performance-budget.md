# CI Performance Budget

## Intent

Performance regressions should fail before they reach users. Large history
loading, large diff parsing, and binary image setup are core Git-client paths,
so they belong in normal macOS CI instead of living as optional local checks.

## Requirements

- Run the deterministic large-repository performance smoke in the GitHub Actions
  macOS validation job.
- Keep the interactive UI sample as a local release-app diagnostic because it
  depends on the launched app process and macOS accessibility-driven sidebar
  toggling.
- Include `script/perf_ui_sample.sh` in shell syntax validation so the local
  diagnostic script does not drift.
- Document the large-repository performance smoke as a standard validation gate.

## Acceptance

- `.github/workflows/ci.yml` runs `./script/perf_large_repo.sh` on push and pull
  request validation.
- CI shell syntax validation includes both performance scripts.
- README and the release checklist list `./script/perf_large_repo.sh` with the
  standard non-credentialed gates.
