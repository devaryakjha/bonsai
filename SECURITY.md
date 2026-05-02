# Security Policy

## Supported Versions

Bonsai is pre-v1 software. Security fixes are handled on the `main` branch until
the project publishes versioned releases.

## Reporting a Vulnerability

Please do not open a public issue for a suspected security vulnerability. Report
it privately to the maintainers with:

- Affected Bonsai version or commit.
- macOS version.
- Steps to reproduce.
- Expected and actual behavior.
- Any logs or sample repositories needed to reproduce the issue.

Maintainers should acknowledge reports within 7 days when possible and keep the
reporter updated while a fix is prepared.

## Scope

Security-sensitive areas include:

- Running Git or provider commands with user-controlled input.
- Handling repository paths, remote URLs, and file previews.
- GitHub token storage and provider API requests.
- Destructive operations such as delete, reset, discard, and remove.

Do not include real access tokens, private repository data, or proprietary source
files in reports.
