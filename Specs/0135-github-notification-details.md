# Spec 0135: GitHub Notification Details

## Objective

Make fetched GitHub notifications inspectable without turning the sidebar into a
feed.

## Requirements

- The GitHub integration row must stay quiet by default and continue showing
  only the unread count.
- Fetched notifications must be available behind an opt-in disclosure.
- Notification rows must show the thread title and repository/type context.
- Rows must expose open-in-browser and copy actions from the context menu.
- GitHub API subject URLs must be converted to GitHub web URLs before opening or
  copying.
- The visible notification list must remain capped to the existing summary cap.

## Acceptance

- A fetched pull request notification can open its GitHub web URL.
- Notifications remain hidden unless the user expands the disclosure.
- URL conversion is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
