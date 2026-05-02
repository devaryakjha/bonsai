# Bonsai Interface Standards

Bonsai should feel like a native professional Git client: calm by default,
precise under inspection, and never playful with critical developer workflows.

## Copy Rules

- Use Git's established vocabulary: commit, amend, stage, unstage, stash,
  rebase, remote, branch, tag, worktree, hunk, patch, blame.
- Use sentence case for in-view labels, placeholders, buttons, empty states,
  tooltips, and accessibility labels.
- Use macOS menu-style title case only for menu commands and command menus.
- Prefer short noun labels for surfaces and settings: `Commit settings`,
  `Diff options`, `File actions`.
- Prefer verb labels for actions: `Stage`, `Unstage`, `Commit`, `Abort`,
  `Reveal in Finder`.
- Use conventional compact notation for Git tracking badges: `↑ 2`, `↓ 1`, or
  `↑ 2 ↓ 1`, not spelled-out `up` / `down` labels.
- Do not use cute, playful, apologetic, or explanatory copy in the product UI.
- Do not add visible instructional copy when a tooltip, menu placement,
  placeholder, or empty state can carry the context.
- Empty states should say what is true, not what the user should feel:
  `Nothing staged`, `No diff selected`, `No local branches`.

## Control Rules

- Keep the primary action visible and direct.
- Keep secondary and destructive actions opt-in through menus, context menus, or
  explicit disclosure.
- Do not show optional metadata by default unless it changes the next decision.
- Use icon-only buttons for compact tool actions when the icon is standard; add
  a tooltip and accessibility label.
- Avoid repeated inline utility icons in rows. One primary row action plus one
  file/actions menu is the default pattern.
- Visible labels must not wrap inside compact controls. Use a wider layout,
  truncation with tooltip, or an icon-only system control when space is tight.

## Layout Rules

- Preserve stable row height and alignment when optional actions appear.
- Use native macOS list, menu, toolbar, disclosure, and inspector patterns before
  custom chrome.
- Reserve dense metadata for detail panes or inspectors, not sidebars and file
  rows.
- Prefer opt-in detail disclosure over always-visible explanatory panels.
- Treat destructive actions as visually quieter but always reachable.

## Review Checklist

- Is the default surface showing only the controls needed for the current
  decision?
- Are optional details behind disclosure, a menu, or an inspector?
- Does every visible label use the copy rules above?
- Can the longest expected text fit without wrapping or overlapping?
- Are tooltips and accessibility labels still present when visible text is
  shortened?
