# Spec 0131: Reference Sidebar Overflow

## Objective

Keep the sidebar calm for repositories with many remote branches and tags
without silently hiding references.

## Requirements

- The remote-branches-and-tags disclosure shows the total reference count.
- The default view may cap visible remote branches and tags to preserve sidebar
  scanability.
- When a cap hides references, the sidebar must show an explicit action to reveal
  all references.
- Users can return to the capped view from the same disclosure.
- Existing reference context-menu actions remain unchanged.

## Acceptance

- Large repositories no longer silently hide remote branches or tags.
- The default sidebar remains capped and calm.
- Reference overflow policy is covered by unit tests.
- `swift test`, the app verification script, and whitespace checks pass.
