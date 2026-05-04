# Spec 0301: Release DMG Installer

## Intent

Bonsai's public macOS release artifact should match the familiar direct
download installation flow: open a disk image, drag `Bonsai.app` to
Applications, and keep the manifest as release evidence.

## Requirements

- Produce `dist/release/Bonsai.dmg` for archive-producing release modes instead
  of `dist/release/Bonsai.zip`.
- Stage the disk image with `Bonsai.app` and an `Applications` symlink that
  points to `/Applications`.
- Validate the generated disk image by mounting it read-only and checking the
  app bundle metadata, signature, and Applications shortcut.
- Keep `Bonsai.release.plist` as the machine-readable artifact manifest, with
  `archiveName`, byte size, SHA-256, signing, and notarization fields referring
  to the DMG.
- Upload the DMG and manifest from the manual GitHub release workflow.

## Acceptance

- `make release-verify-archive` writes and validates
  `dist/release/Bonsai.dmg`.
- `make release-verify-artifacts` verifies `Bonsai.dmg` against
  `Bonsai.release.plist`.
- The GitHub draft release helper uploads `Bonsai.dmg` and the manifest.
- Release docs describe the drag-to-Applications disk image install flow.
