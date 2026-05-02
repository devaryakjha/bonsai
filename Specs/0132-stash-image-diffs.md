# Spec 0132: Stash Image Diffs

## Objective

Make image changes inside stashes use the same before/after preview surface as
working-tree and commit image changes.

## Requirements

- Stash image changes load the base image from the stash parent.
- Stash image changes load the stashed image from the stash tree.
- Added or deleted stash image sides remain optional so the image diff view can
  show its existing missing-side placeholder.
- Stash image blob retrieval stays behind `GitClient`.

## Acceptance

- Integration tests cover before/after image data for a real stash.
- Selecting an image file inside a stash sets an image diff snapshot.
- `swift test`, the app verification script, and whitespace checks pass.
