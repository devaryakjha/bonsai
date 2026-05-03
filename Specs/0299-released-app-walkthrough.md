# Spec 0299: Released App Walkthrough

## Intent

Verify the public GitHub Release artifact as an installed user would receive it,
not only the source tree, CI build, or local package verifier.

## Requirements

- Download the published `v0.1.0` asset pair from GitHub Releases.
- Extract `Bonsai.zip` and validate the expanded app with Apple stapler and
  Gatekeeper.
- Launch the expanded released app bundle, not a freshly built local bundle.
- Open a real Git repository with at least one commit and working-tree changes.
- Verify the visible app surface loads repository identity, branch state,
  working-tree status, history, changed files, and rich split diff content.
- Sample sidebar toggling from the released app after warm-up and fail if known
  diff/header/parser hot frames appear during the interaction window.

## Evidence

- Published release:
  `https://github.com/devaryakjha/bonsai/releases/tag/v0.1.0`.
- Download command:
  `gh release download v0.1.0 --repo devaryakjha/bonsai --dir /tmp/bonsai-release-walkthrough/app --pattern 'Bonsai*'`.
- Stapler validation passed on
  `/tmp/bonsai-release-walkthrough/app/expanded/Bonsai.app`.
- Gatekeeper accepted the expanded app with `source=Notarized Developer ID` and
  origin `Developer ID Application: Aryakumar Jha (KZX5HZ32P9)`.
- Audit repository:
  `/tmp/bonsai-release-walkthrough/repo`.
- History screenshot:
  `/tmp/bonsai-release-walkthrough/screens/main.png`.
- Working-tree screenshot:
  `/tmp/bonsai-release-walkthrough/screens/changes.png`.
- Released app sidebar sample:
  `/tmp/bonsai-release-walkthrough/released-app-sidebar.sample.txt`.
- The released app sidebar sample reported `hot_frames=0` for
  `SystemSegmentedControl`, rich/split attributed diff rendering,
  `GitParsers.parse`, and `DiffHeaderControls` during the interaction window.

## Acceptance

- The expanded release app launches from the downloaded archive.
- The app opens the audit Git repository and renders repository, branch,
  working-tree, history, changed-file, and split-diff surfaces.
- The working-tree screenshot shows the dirty README diff in split mode and the
  untracked file list.
- The interaction sample reports `hot_frames=0`.
