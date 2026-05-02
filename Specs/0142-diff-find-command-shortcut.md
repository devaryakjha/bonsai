# Spec 0142: Diff Find Command Shortcut

## Objective

Align Bonsai with standard macOS find behavior by reserving `Command-F` for
finding in the active diff surface.

## Requirements

- `Command-F` opens the diff find field when a diff surface is focused.
- Running the command again keeps the field open instead of clearing the query.
- Fetch no longer uses `Command-F`.
- Fetch remains reachable from the Repository menu and keeps a keyboard
  shortcut that does not conflict with standard Find.
- The command routing stays view-owned through SwiftUI focused values rather
  than introducing global view references.

## Acceptance

- The Repository command menu exposes Fetch without stealing `Command-F`.
- The Edit command group exposes Find in Diff with `Command-F`.
- Closing the find field from the header still clears the query.
