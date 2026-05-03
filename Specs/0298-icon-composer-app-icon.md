# Spec 0298: Icon Composer App Icon

## Intent

Bonsai should use the modern Icon Composer app-icon source as the canonical
asset, while keeping a generated `.icns` fallback for the manual SwiftPM bundle
pipeline.

## Requirements

- Treat `Assets/AppIcon/Bonsai.icon` as the source of truth for light, dark, and
  tinted app icon appearances.
- Keep export automation non-destructive: it may rewrite
  `Assets/AppIcon/Bonsai.icns`, but it must not rewrite the `.icon` package.
- Add a `make app-icon` target so maintainers do not call exporter scripts
  directly.
- Copy `Bonsai.icon` into app bundles and release archives alongside
  `Bonsai.icns`.
- Validate the icon document is present during release packaging.

## Acceptance

- `make app-icon` succeeds with Icon Composer's `ictool`.
- `make release-verify` validates that the staged bundle contains
  `Contents/Resources/Bonsai.icon/icon.json`.
- Tests cover the `.icon` source package and release-script integration.
