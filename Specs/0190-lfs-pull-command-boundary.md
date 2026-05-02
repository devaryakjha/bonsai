# Spec 0190: Git LFS Pull Command Boundary

## Intent

Git LFS pull is part of the v0 Git LFS parity surface. Its command arguments
should be covered by the same testable boundary used for fetch, checkout, prune,
and unlock.

## Requirements

- Route `lfsPull` through a static argument builder.
- Keep the executed command as `git lfs pull`.
- Do not change toolbar or command-menu reachability.

## Acceptance

- Command argument coverage proves Git LFS pull uses `["lfs", "pull"]`.
- Existing Git LFS command argument tests remain green.
- Validation gates pass.
