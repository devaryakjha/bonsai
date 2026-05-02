# Spec 0220: Multiple Source Directories

## Objective

Support more than one local source directory in the repository manager while
preserving the existing `~/projects` default.

## Requirements

- Keep `~/projects` as the default source directory.
- Allow multiple source directories through a newline-separated Settings value.
- Ignore empty duplicate paths.
- Scan every configured source directory when building workspace groups.
- Keep root labels clear when more than one source directory is configured.
- Keep the sidebar rescan action tied to the configured source directories.

## Acceptance

- Unit coverage proves source-directory parsing and multi-root grouping.
- The sidebar no longer hardcodes `~/projects` as the workspace source label.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
