# Spec 0153: App Logo Asset

## Objective

Use the Bonsai worktree topology mark as the app logo wherever the current
SwiftPM macOS packaging can support it cleanly.

## Requirements

- Keep the provided SVG source in a stable, OSS-friendly asset directory.
- Keep `Assets/AppIcon/Bonsai.icon` as the canonical Icon Composer source.
- Export the generated `.icns` from `Bonsai.icon`; do not hand-generate or
  overwrite the `.icon` package from scripts.
- Bundle the generated `.icns` app icon and the canonical `.icon` package into
  the manually built `.app` bundle.
- Set the app bundle icon through `CFBundleIconFile` and `CFBundleIconName`.
- Use the same topology mark in the empty repository surface without adding
  extra explanatory copy.
- Keep the in-app mark theme-aware so it works in Light and Dark mode.

## Acceptance

- `make app-icon` exports `Assets/AppIcon/Bonsai.icns` from
  `Assets/AppIcon/Bonsai.icon`.
- `script/build_and_run.sh --verify` builds an app bundle that contains
  `Contents/Resources/Bonsai.icns`, `Contents/Resources/Bonsai.icon`, and
  declares `CFBundleIconFile` and `CFBundleIconName`.
- The empty repository state renders the topology mark instead of the previous
  generic SF Symbol.
- `swift test`, the app verification script, and whitespace checks pass.
