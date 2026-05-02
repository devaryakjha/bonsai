# Spec 0227: Ignored Files Toggle

## Objective

Let users show or hide ignored files in the working-tree view without changing
the default quiet status surface.

## Requirements

- Keep ignored files hidden by default.
- Add a Git menu action that toggles ignored-file visibility.
- Bind the menu action to `Command-Shift-.`.
- Add a compact working-tree header affordance for the same toggle.
- Read ignored paths from Git using porcelain status with ignored matching.
- Render ignored files in a separate passive section.
- Do not allow ignored rows to be staged, discarded, or ignored again.
- Preserve existing staged, unstaged, untracked, and conflicted behavior.

## Acceptance

- Command argument coverage proves ignored status is opt-in.
- Parser coverage proves `!!` status rows become ignored entries.
- Integration coverage proves enabling the toggle refreshes ignored rows.
- `swift test`, the app verifier, and whitespace checks pass.
