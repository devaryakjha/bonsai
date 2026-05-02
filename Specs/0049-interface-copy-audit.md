# Spec 0049: Interface Copy Audit

## Objective

Apply Bonsai's interface standards to visible dialogs, form labels, compact
controls, and command-output titles so the product language is consistent and
professional across common workflows.

## Requirements

- In-view labels, sheet titles, form labels, and command-output status titles
  must use sentence case.
- macOS command menus may keep title case.
- Git and platform acronyms such as GitHub, Git LFS, GPG, and URL must keep
  their established capitalization.
- Branch tracking badges must use industry-standard ahead/behind arrow notation.
- Copy changes must not remove existing actions or reduce feature reachability.

## Acceptance

- Dialog-heavy surfaces use sentence-case titles and labels.
- Diff hunk controls use the same copy rules as the rest of the app.
- Command output titles use sentence case where they are product UI.
- Branch ahead/behind badges show arrow notation instead of `up` / `down` copy.
- `swift test`, the app verification script, and whitespace checks pass.
