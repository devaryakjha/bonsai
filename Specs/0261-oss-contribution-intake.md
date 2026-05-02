# Spec 0261: OSS Contribution Intake

## Intent

Prepare Bonsai for public issue and pull request traffic without losing the
project's spec-driven workflow or accepting vague UI reports.

## Requirements

- Add GitHub issue forms for bug reports and feature requests.
- Disable blank public issues so reports stay structured.
- Route security reports to `SECURITY.md` instead of public issue threads.
- Add a pull request template that asks for the spec, behavior summary,
  validation, and UI evidence when relevant.
- Keep template language direct and professional.

## Acceptance

- `.github/ISSUE_TEMPLATE/bug_report.yml` captures macOS version, Bonsai
  version or commit, repository scenario, reproduction steps, expected behavior,
  actual behavior, and validation notes.
- `.github/ISSUE_TEMPLATE/feature_request.yml` asks for the workflow, Fork
  parity impact, proposed behavior, and validation evidence.
- `.github/ISSUE_TEMPLATE/config.yml` disables blank issues and links security
  reports to `SECURITY.md`.
- `.github/pull_request_template.md` mirrors the contribution workflow.
- `git diff --check` and YAML parsing for the issue forms pass.
