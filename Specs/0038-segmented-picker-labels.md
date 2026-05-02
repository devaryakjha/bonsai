# Spec 0038: Segmented Picker Labels

## Objective

Prevent segmented-control labels from wrapping or occupying visible layout space in dense macOS panes and sheets.

## Requirements

- Segmented pickers outside form-style settings must hide their visible SwiftUI labels when nearby UI already provides context.
- Hidden labels must remain available as accessibility labels.
- Dense headers and sheets must avoid rendering standalone labels such as "Mode", "Algorithm", or "Commit Panel" beside segmented controls.

## Acceptance

- The main History/Changes mode picker has no visible picker label.
- Reset mode pickers in reset sheets have no visible picker label.
- Existing diff and commit-panel segmented controls remain label-hidden.
- The app builds successfully.
