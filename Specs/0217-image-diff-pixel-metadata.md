# Spec 0217: Image Diff Pixel Metadata

## Intent

Show image diff metadata in pixel dimensions so before/after inspection is
accurate for bitmap assets.

## Requirements

- Image panes report pixel width and height from decoded bitmap data when
  available.
- File size remains visible next to dimensions.
- If pixel data cannot be resolved, fall back to the existing image size.
- Keep metadata compact and subordinate to the image.

## Acceptance

- Unit coverage proves metadata uses decoded pixel dimensions.
- Unit coverage proves fallback dimensions remain available.
- Image diff panes continue to show dimensions and file size for valid image
  data.
- SwiftPM tests, app verifier, and whitespace checks pass.
