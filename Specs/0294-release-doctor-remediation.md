# Release Doctor Remediation

## Intent

The remaining v0 blocker is private Apple release credential setup. When
`--github-doctor` reports that the protected release environment is not ready,
the output should tell a maintainer the exact safe command sequence to finish
the setup without exposing secret values.

## Requirements

- Keep `script/package_release.sh --github-doctor` read-only.
- When GitHub release configuration is not ready, print the no-secret
  remediation sequence:
  - print the local export template;
  - validate local Apple release inputs without uploading;
  - upload the protected environment secrets;
  - rerun the doctor;
  - run a Jarvis dry run;
  - dispatch the protected release after the doctor passes.
- Do not print remediation text when the GitHub release configuration is ready.
- Cover the not-ready and ready paths in release script tests.

## Acceptance

- `--github-doctor` still exits non-zero while required environment secrets are
  missing.
- The not-ready output includes the exact safe commands for the credential
  handoff and workflow dispatch.
- The ready output remains concise and does not suggest setup work.
