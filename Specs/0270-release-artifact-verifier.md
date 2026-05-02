# Spec 0270: Release Artifact Verifier

## Intent

Let maintainers and downstream users verify a Bonsai release zip against its
manifest after the artifacts have been downloaded or moved, without rebuilding
the app.

## Requirements

- Add `script/package_release.sh --verify-artifacts`.
- Validate the release zip structure using the existing archive verifier.
- Validate the release manifest shape using the existing manifest verifier.
- Compare manifest `archiveName`, `archiveByteSize`, and `archiveSHA256` to the
  actual `dist/release/Bonsai.zip`.
- Return a non-zero exit status for missing files or mismatched manifest data.
- Do not build, sign, submit, staple, or mutate artifacts from this mode.

## Acceptance

- `./script/package_release.sh --verify-artifacts` passes after
  `--verify-archive`.
- Release docs include the verifier in local and post-release validation.
