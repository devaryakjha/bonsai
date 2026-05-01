# GitHub Repository Management Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Cover the remote repository create/delete portion of Fork parity for GitHub using
the existing token-based provider setup.

## Requirements

- User can create a GitHub repository for the authenticated user.
- User can choose whether the new repository is private.
- User can delete a GitHub repository by owner/name with explicit confirmation.
- GitHub network calls are isolated in `GitHubClient`.
- Successful create returns the clone URL and can be copied from command output.

## API Notes

GitHub's repository REST API exposes authenticated-user repository creation via
`POST /user/repos` and repository deletion via `DELETE /repos/{owner}/{repo}`.
Deleting requires elevated token permissions such as classic `delete_repo`.

Source: https://docs.github.com/rest/repos/repos

## Acceptance Checks

- GitHub repository JSON decoding is unit-tested.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
