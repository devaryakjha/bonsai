# Spec 0111: History Panel Options

## Objective

Make optional commit-row metadata discoverable from the history panel without
showing the metadata by default.

## Requirements

- The history search header exposes a compact options menu.
- The options menu toggles commit row details using the existing persisted
  setting.
- The default history row remains one line.
- The control uses hover help and accessibility labels instead of visible
  explanatory text.
- Commit search behavior remains unchanged.

## Acceptance

- Users can opt into commit row details from the history panel.
- The Settings toggle and history panel toggle stay backed by the same stored
  preference.
- `swift test`, the app verification script, and whitespace checks pass.
