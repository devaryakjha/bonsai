# Bonsai Product Spec

Status: Draft v0
Date: 2026-05-02

## Objective

Build Bonsai as a free, open-source, native macOS Git client with v0 feature
parity to Fork while keeping a modern, premium desktop feel.

## Product Principles

- Native first: SwiftUI/AppKit where needed, system sidebars, menus, keyboard
  shortcuts, split views, inspectors, sheets, and semantic materials.
- Git truth first: Git CLI output is the source of truth unless a future libgit2
  layer proves necessary for performance.
- Fast feedback: repository state must refresh predictably after every mutation.
- OSS ready: clear specs, narrow services, testable command layer, no private
  service assumptions.
- Premium restraint: dense but calm layout, predictable interaction, no marketing
  chrome inside the app.

## Fork Parity Matrix

Current public Fork sources list these v0 parity surfaces:

| Area | v0 Requirement | Acceptance |
| --- | --- | --- |
| Repository manager | Create, clone, add existing repos, recent repos, workspace grouping | User can add/open a repo and return to it from recents |
| Core remote ops | Fetch, pull, push | Actions call Git and refresh visible state |
| Commit workflow | Stage/unstage files and hunks, commit, amend, recent messages | User can create a commit from selected changes |
| History | Commit graph/list, commit details, file list, search/filter | User can inspect branch history and selected commit changes |
| Diff viewer | Side-by-side source diffs, image diff placeholders, binary handling | Text diffs are readable and selectable |
| Branches/tags | Create/delete/checkout branches and tags | Sidebar state reflects Git refs |
| Revision actions | Checkout revision, cherry-pick, revert, merge, rebase | Primary revision actions are available from toolbar/context menus |
| Stashes | Create/apply/pop/drop stashes, show stashes in history | User can manage stashes without terminal |
| Submodules | List and update submodules | User can see submodule state and run update |
| Conflict resolution | Detect conflicts and provide resolver workflow | Conflicted files are grouped and launch a resolution surface |
| Interactive rebase | Edit, reorder, squash commits | User can stage an interactive rebase plan before execution |
| Reflog | Show reflog and restore lost commits | User can inspect reflog and checkout/reset to entries |
| File history/blame | File history and blame views | User can inspect a path across commits and line ownership |
| Git-flow | Feature/release/hotfix start/finish actions | Git-flow commands are exposed when initialized |
| Git LFS | Detect LFS, show LFS files, pull, lock/unlock selected files | LFS status appears and basic commands are available |
| GPG | Respect commit signing config | Commit flow exposes sign toggle/status |
| Provider notifications | GitHub notifications and repository actions without noise | GitHub provider actions stay token-based and opt-in |

## v0 App Surfaces

- Main window: `NavigationSplitView` with repository/sidebar, history/working
  tree center, and details/diff inspector.
- Repository manager: first-run empty state, add existing repo, clone placeholder,
  recents, and workspace groups.
- Working tree: staged/unstaged/conflicted/untracked groups, stage/unstage,
  discard confirmation, commit message, amend/sign toggles.
- History: commit list with graph lane placeholder, branch/tag labels, commit
  details, changed files, diff.
- References: local branches, remote branches, tags, remotes.
- Operations: fetch, pull, push, branch, tag, stash, merge, rebase,
  cherry-pick, revert, checkout, reset.
- Utility windows/sheets: clone, settings, command output, conflict resolver,
  interactive rebase, reflog, blame, file history.

## Architecture

- `Services/GitClient.swift`: process boundary for Git commands.
- `Stores/RepositoryStore.swift`: selected repo, recents, refresh orchestration.
- `Models/`: parsed Git domain values.
- `Views/`: split app surfaces with explicit action routing.
- `Support/`: parsers, formatters, process helpers.

## Milestones

1. Native scaffold, run script, repository open flow, Git command service.
2. Repository summary: status, branches, remotes, tags, stashes, submodules.
3. History and diff browsing.
4. Working tree staging and commit/amend.
5. Branch/tag/remote/stash actions.
6. Merge/rebase/cherry-pick/revert/reset flows.
7. Reflog, blame, file history.
8. Conflict resolver and interactive rebase surfaces.
9. Git LFS, GPG, Git-flow.
10. GitHub notifications and provider accounts.

## Parity Evidence

Current implementation evidence for each v0 parity surface is tracked in
`Specs/0242-v0-parity-evidence.md`. That matrix is the working audit source and
does not replace a fresh completion audit against Fork before declaring v0 done.

## Source Notes

- Fork public homepage feature overview, refreshed 2026-05-03:
  https://www.fork.dev/
- Fork public macOS release notes, refreshed 2026-05-03:
  https://fork.dev/releasenotes
