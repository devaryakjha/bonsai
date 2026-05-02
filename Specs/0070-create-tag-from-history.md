# Spec 0070: Create Tag From History

## Objective

Let users create tags directly from a history row, matching the existing branch
creation affordance and reducing unnecessary toolbar round trips.

## Requirements

- Commit history context menus must expose `Create Tag Here`.
- The action must select the clicked commit before opening the tag sheet.
- Confirming the sheet must create the tag at the selected commit, not
  accidentally at `HEAD`.
- Existing toolbar tag creation must keep working.

## Acceptance

- History rows expose branch and tag creation side by side.
- Store-level integration coverage proves tags can be created at a selected
  non-HEAD commit.
- `swift test`, the app verification script, and whitespace checks pass.
