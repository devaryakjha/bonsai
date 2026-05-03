# Spec 0241: App About Branding

## Intent

Use the Bonsai worktree topology logo consistently in macOS-owned app surfaces,
not only inside custom SwiftUI content. The app icon and About panel should carry
the same identity as the repository header, setup sheets, README, and bundle
assets.

## Requirements

- Install the bundled Bonsai icon as the runtime application icon when the app
  launches.
- Replace the default About item with a Bonsai-specific About command.
- Use the bundled `Bonsai.icns` first, keep `Bonsai.icon` as the canonical app
  icon source, and keep the topology SVG as the named mark fallback.
- Keep the About panel copy short and product-grade.
- Preserve the existing manual app bundle packaging path.

## Acceptance

- Unit coverage pins the About panel identity, icon option, and resource names.
- Release packaging validates the bundled `Bonsai.icon` package alongside the
  `.icns` fallback.
- `swift test`, the app verifier, and whitespace checks pass.
