# Spec 0218: Binary Preview Status Copy

## Objective

Make binary and image diff previews identify the selected change state without
adding another dense metadata block.

## Requirements

- Show a compact status line in binary and image previews.
- Prefer the selected Git status title when one is available.
- Keep the fallback copy short when a preview has no Git status context.
- Preserve middle truncation for long file paths.
- Keep image before/after panes focused on the image content.

## Acceptance

- Binary preview status copy is unit-tested.
- `swift test` passes.
- `./script/build_and_run.sh --verify` passes.
