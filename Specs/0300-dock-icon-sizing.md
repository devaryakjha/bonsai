# Spec 0300: macOS Icon Canvas Sizing

## Intent

Bonsai should read as a native macOS app icon in Dock, app switcher, and other
launcher surfaces. The topology mark should be recognizable without crowding the
neighboring system app icons.

## Requirements

- Keep `Assets/AppIcon/Bonsai.icon` as the canonical app-icon source.
- Preserve the Icon Composer foreground composition instead of shrinking the mark
  to compensate for export sizing.
- Export the full rendered Icon Composer image inside a transparent macOS icon
  canvas live area, matching the standard app-icon envelope used by system apps.
- Regenerate `Assets/AppIcon/Bonsai.icns` from the Icon Composer source and
  padded export pipeline.

## Acceptance

- Exported iconset PNGs keep transparent canvas margins around the full
  rounded-square app icon.
- `make app-icon` regenerates `Assets/AppIcon/Bonsai.icns`.
- `swift test --filter ReleaseScriptTests/testIconComposerDocumentIsCanonicalAppIconSource`
  passes.
