# Spec 0242: v0 Parity Evidence

## Intent

Keep Fork-parity progress auditable from the repository instead of relying on
stale draft labels or memory. This is a working evidence matrix, not a v0
completion claim.

## Scope

This spec maps the v0 surfaces from `Specs/0001-product-spec.md` to concrete
implementation and verification evidence currently present in the tree. A row is
`verified` only when command boundaries, store behavior, or parser behavior are
covered by tests and the app verifier can still launch the bundle.

## Evidence Matrix

| Area | Current evidence | Status |
| --- | --- | --- |
| Repository manager | `RepositoryStore.openRepository`, clone/create setup sheets, recent repositories, workspace group scanner, and `ProjectRepositoryScannerTests` | Verified |
| Core remote ops | Fetch, pull, push, force-push-with-lease, single-remote fetch, remote prune, and upstream-aware command builders in `GitClientCommandArgumentsTests` and integration tests | Verified |
| Commit workflow | File, hunk, line, and bulk stage/unstage; commit, amend, signing, recent messages, and readiness checks in `GitClientIntegrationTests` | Verified |
| History | Commit graph/list, commit details, search filtering, stashes in history, commit tree browsing, and commit context menus | Verified |
| Diff viewer | AppKit-backed selectable unified/split renderers, histogram/patience/Myers/minimal algorithms, non-wrapping gutters, bounded large-diff actions, inline highlights, find, image before/after, and binary placeholders | Verified |
| Branches and tags | Create, rename, delete, checkout, publish, pull/push selected refs, upstream management, web targets, and tag transfer actions | Verified |
| Revision actions | Checkout revision, cherry-pick, revert, merge, rebase, reset, bisect, patch copy, and grouped context/toolbar command surfaces | Verified |
| Stashes | Create, include untracked, apply, pop, drop, branch from stash, copy patch, and stash diff/image inspection | Verified |
| Submodules | Recursive listing, state parsing, sidebar presentation, global update, single update, open, reveal, and terminal actions | Verified |
| Conflict resolution | Conflicted grouping, preview sheet, base/ours/theirs resolved diffs, ours/theirs/mark-resolved routing, command builders, and integration conflict coverage | Verified |
| Interactive rebase | Todo plan generation, action changes, row movement, validation, `GIT_SEQUENCE_EDITOR` execution, and update-refs option | Verified |
| Reflog | Reflog sheet, checkout, reset confirmation, parser coverage, and integration recovery checks | Verified |
| File history and blame | Structured file history, blame sheets, search, copy actions, and jump-to-commit from inspection rows | Verified |
| Repository analytics | Opt-in benchmark and treemap sheets with scale metrics, weighted tracked-size visualization, command builders, and integration coverage | Verified |
| Git-flow | Availability/init detection plus feature/release/hotfix start and finish actions | Verified |
| Git LFS | Availability, file listing, pull, checkout, fetch, prune, selected-file lock/unlock, force unlock, and sidebar actions | Verified |
| GPG | Signing config detection, repository signing toggle, per-commit sign state, and command-result feedback | Verified |
| Provider notifications | Token-gated GitHub notifications, mark-read, browser targets, repository create/delete sheets, and provider error copy | Verified |
| App identity and OSS shape | MIT license, contribution/security docs, README logo, bundled app icon, About panel branding, specs, and tests | Verified |
| Release packaging readiness | Dedicated release packaging script, credential-free ad-hoc verification, Developer ID signing hook, notarization hook, and release documentation | Verified |

## Latest Fork Release-Note Delta

The parity target was refreshed against the Fork homepage and Mac release notes
on 2026-05-03. The current public release-note page lists Fork 2.66 and newer
surfaces that are not all represented in the older homepage matrix.

Source checked: `https://fork.dev/releasenotes`, whose Mac release notes showed
Fork 2.66 dated 10 Apr 2026 at the time of this refresh.

| Release-note surface | Bonsai status |
| --- | --- |
| Multiple source code directories | Verified |
| Hunk history from the file tree / selected-code history | Verified |
| Worktree branch icon | Verified |
| SVG and TGA image support | Verified |
| External editor reveal/open-in integrations | Verified |
| Claude branch review and generated commit messages | Verified through `Specs/0251-claude-generated-commit-message.md` and `Specs/0252-claude-branch-review.md` |
| Codex AI commit messages and code review | Verified through `Specs/0254-code-agent-provider-parity.md` |
| Editable default AI agent requests in Integration preferences | Verified through `Specs/0287-editable-code-agent-requests.md` |
| Cmd+V to apply patch from clipboard | Verified through `Specs/0253-apply-patch-clipboard-shortcut.md` |
| Collapsible commit details | Verified |
| Keyboard navigation in sidebar | Verified through `Specs/0258-sidebar-keyboard-navigation.md` |
| Cherry-pick/revert conflict-readiness indicators | Verified through `Specs/0255-revision-conflict-preflight.md` |
| Copy repository path from sidebar repository menu | Verified |
| .gitignore template picker | Verified |
| Conflict-resolved diffs after external merge tools | Verified |
| Repository benchmark | Verified |
| Repository treemap | Verified |
| Large-repository history and diff performance pass | Verified through `Specs/0256-large-repository-performance-pass.md` |
| Compact/wide visual QA | Verified through `Specs/0257-visual-qa-adaptive-split-diff.md` |
| Ahead/behind pull and push toolbar counts | Verified through `Specs/0040-toolbar-tracking-counts.md` and `Specs/0109-tracking-action-arrow-labels.md` |
| Select stale local branches | Verified through `Specs/0286-stale-local-branch-selection.md` |
| Copy path from worktree and submodule context menus | Verified through `Specs/0085-copy-infrastructure-values.md` |
| Verbose Git output preference | Verified through `Specs/0288-verbose-git-output-preference.md` |

## Release Evidence

- GitHub `Release` run
  `https://github.com/devaryakjha/bonsai/actions/runs/25278300708` produced a
  Developer ID signed and notarized `Bonsai.zip` for commit
  `d817e8bb8d20f5126b93a712f0e784af2586847e`.
- The published GitHub Release `v0.1.0` has `Bonsai.zip` and
  `Bonsai.release.plist` attached for installation and verification.
- The downloaded release artifact was verified locally with
  `make release-verify-artifacts`, `xcrun stapler validate`, and
  `spctl -a -vv -t exec`.
- The published release assets were downloaded from `v0.1.0` and verified with
  the same artifact, stapler, and Gatekeeper checks.

## Acceptance

- This evidence matrix stays explicit about verified surfaces and remaining
  completion gates.
- Future parity work updates this file when a product-spec row changes status.
- `swift test`, the app verifier, and whitespace checks pass after updates.
