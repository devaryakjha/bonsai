# Spec 0216: Image Diff Missing Side Copy

## Intent

Make before/after image diffs identify the missing side without generic
placeholder copy.

## Requirements

- The before image pane keeps the visible title `Before`.
- The after image pane keeps the visible title `After`.
- A missing before side renders `No previous image`.
- A missing after side renders `No new image`.
- Keep image metadata compact and native.

## Acceptance

- Added-image diffs identify the missing before side.
- Deleted-image diffs identify the missing after side.
- Image dimensions and file size remain visible when image data exists.
- SwiftPM tests, app verifier, and whitespace checks pass.
