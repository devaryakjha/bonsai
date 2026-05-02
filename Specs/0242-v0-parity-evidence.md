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
| Diff viewer | AppKit-backed selectable unified/split renderers, histogram/patience/Myers/minimal algorithms, non-wrapping gutters, inline highlights, find, image before/after, and binary placeholders | Verified |
| Branches and tags | Create, rename, delete, checkout, publish, pull/push selected refs, upstream management, web targets, and tag transfer actions | Verified |
| Revision actions | Checkout revision, cherry-pick, revert, merge, rebase, reset, bisect, patch copy, and grouped context/toolbar command surfaces | Verified |
| Stashes | Create, include untracked, apply, pop, drop, branch from stash, copy patch, and stash diff/image inspection | Verified |
| Submodules | Recursive listing, state parsing, sidebar presentation, global update, single update, open, reveal, and terminal actions | Verified |
| Conflict resolution | Conflicted grouping, preview sheet, base/ours/theirs resolved diffs, ours/theirs/mark-resolved routing, command builders, and integration conflict coverage | Verified |
| Interactive rebase | Todo plan generation, action changes, row movement, validation, `GIT_SEQUENCE_EDITOR` execution, and update-refs option | Verified |
| Reflog | Reflog sheet, checkout, reset confirmation, parser coverage, and integration recovery checks | Verified |
| File history and blame | Structured file history, blame sheets, search, copy actions, and jump-to-commit from inspection rows | Verified |
| Repository analytics | Opt-in repository benchmark sheet with scale metrics, command timing, command builders, and integration coverage | Partial |
| Git-flow | Availability/init detection plus feature/release/hotfix start and finish actions | Verified |
| Git LFS | Availability, file listing, pull, checkout, fetch, prune, selected-file lock/unlock, force unlock, and sidebar actions | Verified |
| GPG | Signing config detection, repository signing toggle, per-commit sign state, and command-result feedback | Verified |
| Provider notifications | Token-gated GitHub notifications, mark-read, browser targets, repository create/delete sheets, and provider error copy | Verified |
| App identity and OSS shape | MIT license, contribution/security docs, README logo, bundled app icon, About panel branding, specs, and tests | Verified |

## Latest Fork Release-Note Delta

The parity target was refreshed against the Fork homepage and Mac release notes
on 2026-05-03. The current public release-note page lists Fork 2.66 and newer
surfaces that are not all represented in the older homepage matrix.

| Release-note surface | Bonsai status |
| --- | --- |
| Multiple source code directories | Verified |
| Hunk history from the file tree / selected-code history | Verified |
| Worktree branch icon | Verified |
| SVG and TGA image support | Verified |
| External editor reveal/open-in integrations | Verified |
| Claude branch review and generated commit messages | Open |
| Conflict-resolved diffs after external merge tools | Verified |
| Repository benchmark | Verified |
| Repository treemap | Open |

## Remaining Completion Gates

- Re-run a fresh parity scrape against current Fork public release notes before
  declaring v0 complete, then close or explicitly defer every open release-note
  delta above.
- Run a large-repository performance pass on history loading and rich diff
  rendering, including split diff and image diff paths.
- Do visual QA on the actual running app for sidebar density, toolbar wrapping,
  sheet sizing, and split diff completeness at compact and wide window sizes.
- Package, sign, and notarization readiness remain outside the current v0
  verifier and need a dedicated release gate before distribution.

## Acceptance

- This evidence matrix stays explicit about verified surfaces and remaining
  completion gates.
- Future parity work updates this file when a product-spec row changes status.
- `swift test`, the app verifier, and whitespace checks pass after updates.
