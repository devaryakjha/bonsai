# Spec 0191: Submodule Update Command Boundary

## Intent

Submodule update is part of the v0 Fork-parity submodule surface. Its command
arguments should be covered at the GitClient boundary, including the path
separator for single-submodule updates.

## Requirements

- Route global submodule update through a static argument builder.
- Route single-submodule update through a static argument builder.
- Preserve `git submodule update --init --recursive`.
- Preserve `--` before a single submodule path.
- Keep existing sidebar and toolbar reachability unchanged.

## Acceptance

- Command argument coverage proves global submodule update arguments.
- Command argument coverage proves single-submodule update arguments preserve
  the path separator and path as one argument.
- Validation gates pass.
