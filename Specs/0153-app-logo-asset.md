# Spec 0153: App Logo Asset

## Objective

Use the Bonsai worktree topology mark as the app logo wherever the current
SwiftPM macOS packaging can support it cleanly.

## Requirements

- Keep the provided SVG source in a stable, OSS-friendly asset directory.
- Bundle a generated `.icns` app icon into the manually built `.app` bundle.
- Set the app bundle icon through `CFBundleIconFile`.
- Use the same topology mark in the empty repository surface without adding
  extra explanatory copy.
- Keep the in-app mark theme-aware so it works in Light and Dark mode.

## Acceptance

- `script/build_and_run.sh --verify` builds an app bundle that contains
  `Contents/Resources/Bonsai.icns` and declares `CFBundleIconFile`.
- The empty repository state renders the topology mark instead of the previous
  generic SF Symbol.
- `swift test`, the app verification script, and whitespace checks pass.
