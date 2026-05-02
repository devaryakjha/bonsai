# Spec 0125: Blame Sheet Accessibility Polish

## Objective

Keep the structured blame sheet dense while avoiding blank text elements and
unlabeled icon-only actions.

## Requirements

- The blame header must not render an empty text label for column alignment.
- The icon-only row action keeps its compact visual form.
- The icon-only row action has a clear accessibility label and hover help.
- Column alignment between the header and rows remains unchanged.
- Blame parsing, navigation, and copy actions remain unchanged.

## Acceptance

- No blank `Text("")` is used in the blame sheet header.
- The blame row commit action is accessible by name.
- The app verification script, `swift test`, and whitespace checks pass.
