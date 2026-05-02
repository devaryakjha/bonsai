# Spec 0275: GitHub Actions Node 24 Runtime

## Intent

Keep Bonsai's public CI and release workflows free of avoidable runtime
deprecation warnings before the v0 open-source release.

## Requirements

- The push and pull-request CI workflow uses a checkout action release that runs
  on Node 24.
- The manual release workflow uses checkout and artifact-upload action releases
  that run on Node 24.
- Existing release artifact verification order and Jarvis runner targeting stay
  unchanged.

## Acceptance

- CI uses `actions/checkout@v6`.
- Release uses `actions/checkout@v6` and `actions/upload-artifact@v7`.
- Release workflow tests pin the action versions alongside the existing
  artifact-verification and Jarvis runner assertions.
- `actionlint`, focused release workflow tests, and whitespace checks pass.
