# Sidebar and Diff Scroll Responsiveness

## Intent

Sidebar collapse, window resizing, and diff scrolling must remain fluid on large
repositories. Layout passes must not rebuild duplicate control trees or use
debug SwiftUI binaries as the normal app run path.

## Requirements

- The local app runner launches a release build for normal run, verify, logs,
  and telemetry modes; debug builds are reserved for the explicit debug mode.
- Hot segmented controls in the always-visible main, commit-file, and diff
  headers use a stable AppKit bridge instead of SwiftUI segmented pickers.
- The diff header does not use `ViewThatFits` to build duplicate full control
  hierarchies during layout.
- Rich diff text views allow non-contiguous layout so AppKit can avoid laying
  out offscreen diff text while scrolling large patches.
- Split diff scroll synchronization skips redundant pane updates when both panes
  are already aligned.
- The optimized controls keep the same selections and accessibility labels.

## Acceptance

- A release app build/verify succeeds through `script/build_and_run.sh --verify`.
- Swift tests remain green after the control bridge and runner changes.
- A sidebar-toggle sample against the release app does not show Bonsai diff
  rendering work as the dominant path.
