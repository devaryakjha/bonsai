# Spec 0178: Hosting Browser URL Resolution

## Intent

Bonsai's browser actions should work for common hosted Git remotes, not only
GitHub. Fork-style workflows often open branches, tags, commits, and remotes in
the hosting provider from context menus, and teams frequently use GitLab or
self-hosted GitLab.

## Requirements

- Keep GitHub API repository management and notifications GitHub-specific.
- Resolve browser URLs for GitHub remotes as before.
- Resolve browser URLs for GitLab remotes, including self-hosted GitLab domains
  and project paths with groups.
- Apply provider-aware browser URLs to remotes, local upstream branches, remote
  branches, tags, current branch commands, and selected commits.
- Keep existing visible actions generic: `Open in Browser`, `Copy Web URL`, and
  browser commands inside the hosting/tools menus.
- Do not add new always-visible controls.

## Acceptance

- A GitHub branch/tag/commit/remote URL is unchanged.
- A GitLab remote such as `git@gitlab.example.com:team/app.git` resolves to
  project, branch, tag, and commit web URLs using GitLab's `/-/` routes.
- A local branch tracking a GitLab remote opens the upstream branch URL.
- Validation gates pass.
