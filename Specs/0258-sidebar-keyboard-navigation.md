# Spec 0258: Sidebar Keyboard Navigation

## Intent

Match the current Fork release-note surface for keyboard navigation in the
sidebar while keeping Bonsai's layout calm. Keyboard users should be able to
move focus between the sidebar and commit list without reaching for the mouse,
then use native list navigation inside the active pane.

## Requirements

- Keep the sidebar as a native macOS sidebar list.
- Give the sidebar a real selection target so arrow-key movement has a stable
  row context.
- Let `Tab` switch focus between the sidebar and history commit list.
- Do not intercept `Tab` while the user is editing text.
- Keep the focus routing small and explicit so it can be tested without UI
  automation.

## Acceptance

- The sidebar list owns a selection binding for repository, recent/source
  repositories, and local branch rows.
- The history commit list and sidebar list expose explicit focus targets.
- `Tab` toggles focus between sidebar and history through a tested policy.
- `swift test`, the app verifier, release packaging verifier, and whitespace
  checks pass.
