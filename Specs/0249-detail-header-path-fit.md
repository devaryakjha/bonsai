# Spec 0249: Detail Header Path Fit

## Intent

Prevent detail-header titles from wrapping into broken path fragments when the
diff toolbar compresses the available width. The header should stay calm and
scanable at realistic window sizes while preserving full paths through help
text.

## Requirements

- File paths in the detail header use a single line with middle truncation.
- Commit subjects in the detail header use a single line with tail truncation.
- Full file paths and subjects remain available through help text.
- The title column gets explicit shrink bounds and layout priority so controls
  do not force awkward word wrapping.
- The header uses an adaptive layout: controls stay beside the title when there
  is room and move below it when the detail pane is narrow.

## Acceptance

- Launch Bonsai against this repository and capture a real app screenshot.
- The selected changed-file header does not wrap `Sources/...` into multiple
  short fragments at a 1280 px window width.
- `swift test`, the app verifier, and whitespace checks pass.
