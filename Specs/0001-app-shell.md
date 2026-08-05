# App shell

## Goal

Bonsai opens as a native macOS application with no repository state or Git
behavior.

## Scope

- Use GPUI for the application and root view.
- Keep the package name as `bonsai`.
- Show the application name and a neutral empty state.

## Non-goals

- Repository selection.
- Git commands or disk access.
- Persistent state.
- Application packaging.

## Acceptance

- `cargo run` opens a Bonsai window.
- The window shows `Bonsai` and `No repository open`.
- The app has no dependency on the prior SwiftUI codebase.
