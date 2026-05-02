# Spec 0113: Compact Commit Composer Controls

## Objective

Keep the commit composer action bar calm at narrow widths by using compact
native controls for secondary actions.

## Requirements

- Recent message reuse remains available when recent messages exist.
- Commit amend and signing controls remain available from the composer.
- Secondary composer menus use icon-only labels with tooltip and accessibility
  text.
- Active optional commit settings remain visible before committing.
- The primary commit button remains the dominant visible action.

## Acceptance

- Composer secondary controls cannot wrap visible text in compact layouts.
- Existing recent-message and commit-option behavior is unchanged.
- `swift test`, the app verification script, and whitespace checks pass.
