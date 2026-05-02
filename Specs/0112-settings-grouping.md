# Spec 0112: Settings Grouping

## Objective

Make Bonsai settings scan like a native macOS preferences panel by grouping
unrelated controls instead of presenting one flat form.

## Requirements

- General display and refresh preferences are grouped together.
- Diff preferences are grouped together.
- GitHub token configuration is grouped separately from local app preferences.
- Existing AppStorage keys and default values remain unchanged.
- Labels stay concise and sentence case.

## Acceptance

- Settings no longer appears as one undifferentiated list.
- Existing preferences continue to read and write the same stored values.
- `swift test`, the app verification script, and whitespace checks pass.
