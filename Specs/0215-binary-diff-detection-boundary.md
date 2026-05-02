# Spec 0215: Binary Diff Detection Boundary

## Intent

Keep source-code diffs on the rich text renderer unless Git has emitted an
actual binary-file diff marker.

## Requirements

- Binary detection matches Git binary marker lines, not arbitrary source text.
- Source diff content containing words such as `differ` remains a text diff.
- Binary marker detection stays independent of image extension detection.
- Existing image and binary preview behavior remains unchanged.

## Acceptance

- Unit coverage proves Git binary marker lines are detected.
- Unit coverage proves normal source lines containing `differ` are not detected
  as binary diffs.
- SwiftPM tests, app verifier, and whitespace checks pass.
