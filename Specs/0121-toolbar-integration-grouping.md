# Spec 0121: Toolbar Integration Grouping

## Objective

Reduce visual load in the toolbar Actions menu by grouping provider and
extension workflows behind clear integration submenus.

## Requirements

- Keep primary repository tools such as patch, submodule, remote, and worktree
  actions directly reachable from the Tools menu.
- Move Git LFS actions into a `Git LFS` submenu.
- Move Git-flow actions into a `Git-flow` submenu.
- Move GitHub notification and repository provider actions into a `GitHub`
  submenu.
- Shorten submenu item labels when the submenu already supplies the provider
  context.
- Preserve existing disabled states and command routing.

## Acceptance

- The toolbar Actions menu has fewer flat top-level rows in its Tools section.
- Git LFS, Git-flow, and GitHub features remain reachable without adding new
  toolbar chrome.
- The app verification script, `swift test`, and whitespace checks pass.
