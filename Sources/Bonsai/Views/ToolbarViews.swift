import SwiftUI

struct RepositoryToolbarActionsMenu: View {
  let store: RepositoryStore
  var showToolbarLabels: Bool

  var body: some View {
    Menu {
      Menu("Branch") {
        Button("Create Branch…") {
          store.presentCreateBranch()
        }
        Button("Create Tag…") {
          store.presentCreateTag()
        }
        Button("Create Annotated Tag…") {
          store.presentCreateAnnotatedTag()
        }
        Divider()
        Button("Force Push with Lease…") {
          store.presentForcePushCurrentBranch()
        }
        .disabled(!store.canForcePushCurrentBranch)
        Button("Checkout Selected Revision") {
          Task { await store.checkoutSelectedCommit() }
        }
        .disabled(store.selectedCommit == nil)
      }

      Menu("Revision") {
        Menu(ToolbarRevisionMenuCopy.selectedCommitMenuTitle) {
          Button(GitRevisionCommand.cherryPick.selectedCommitTitle) {
            store.presentRevisionCommand(.cherryPick)
          }
          .disabled(store.selectedCommit == nil)
          Button(GitRevisionCommand.revert.selectedCommitTitle) {
            store.presentRevisionCommand(.revert)
          }
          .disabled(store.selectedCommit == nil)
          Button(GitRevisionCommand.merge.selectedCommitTitle) {
            store.presentRevisionCommand(.merge)
          }
          .disabled(store.selectedCommit == nil)
          Button(GitRevisionCommand.rebase.selectedCommitTitle) {
            store.presentRevisionCommand(.rebase)
          }
          .disabled(store.selectedCommit == nil)
          Divider()
          Button("Reset to Selected Commit…") {
            store.presentResetToSelectedCommit()
          }
          .disabled(store.selectedCommit == nil)
        }
        Menu(ToolbarRevisionMenuCopy.currentOperationMenuTitle) {
          Button("Continue") {
            Task { await store.runInProgressOperation(.continueOperation) }
          }
          .disabled(!store.snapshot.inProgressOperation.active)
          Button("Skip") {
            Task { await store.runInProgressOperation(.skip) }
          }
          .disabled(!(store.snapshot.inProgressOperation.kind?.canSkip ?? false))
          Button("Abort") {
            Task { await store.runInProgressOperation(.abort) }
          }
          .disabled(!store.snapshot.inProgressOperation.active)
        }
        Menu(ToolbarRevisionMenuCopy.rebaseMenuTitle) {
          Button("Interactive Rebase…") {
            Task { await store.presentInteractiveRebase() }
          }
        }
        Menu(ToolbarRevisionMenuCopy.bisectMenuTitle) {
          Button("Start with Selected Commit…") {
            store.presentStartBisect()
          }
          .disabled(store.selectedCommit == nil || store.snapshot.integrations.bisect.active)
          ForEach(GitBisectMark.allCases) { mark in
            Button("Mark Current Commit \(mark.title)") {
              Task { await store.markBisect(mark) }
            }
            .disabled(!store.snapshot.integrations.bisect.active)
          }
          Button("Reset") {
            Task { await store.resetBisect() }
          }
          .disabled(!store.snapshot.integrations.bisect.active)
        }
      }

      Menu("Stash") {
        Button("Create Stash…") {
          store.presentStashPush()
        }
        Button("Create Stash Including Untracked…") {
          store.presentStashPush(includeUntracked: true)
        }
        Divider()
        ForEach(store.snapshot.stashes) { stash in
          Menu(stash.index) {
            Button("Apply") {
              Task { await store.applyStash(stash, pop: false) }
            }
            Button("Pop") {
              Task { await store.applyStash(stash, pop: true) }
            }
            Button("Create Branch…") {
              store.presentStashBranch(stash)
            }
            Divider()
            StashCopyMenu(stash: stash)
            Button("Copy Patch") {
              Task { await store.copyStashPatch(stash) }
            }
            Divider()
            Button("Drop", role: .destructive) {
              store.presentDropStash(stash)
            }
          }
        }
      }

      Menu("Tools") {
        Button("Show Reflog") {
          Task { await store.showReflog() }
        }
        Button("Show Blame") {
          Task { await store.showBlameForSelection() }
        }
        .disabled(store.selectedChangedFile == nil && store.selectedStatusEntry == nil)
        Button("Show File History") {
          Task { await store.showFileHistoryForSelection() }
        }
        .disabled(store.selectedChangedFile == nil && store.selectedStatusEntry == nil)
        Divider()
        Button("Copy Current Patch") {
          store.copyCurrentPatch()
        }
        .disabled(!store.canCopyCurrentPatch)
        Button("Apply Patch from Clipboard") {
          store.presentApplyPatchFromClipboard()
        }
        Button("Open Selected File") {
          store.openSelectedFile()
        }
        .disabled(!store.canOpenSelectedFile)
        Button("Copy Selected File Absolute Path") {
          store.copySelectedFileAbsolutePath()
        }
        .disabled(!store.canCopySelectedFileAbsolutePath)
        Button("Discard Unstaged Changes…", role: .destructive) {
          store.presentDiscardUnstagedChanges()
        }
        .disabled(!store.canDiscardUnstagedChanges)
        Divider()
        Button("Update Submodules") {
          Task { await store.updateSubmodules() }
        }
        Button("Add .gitignore Template…") {
          store.presentGitIgnoreTemplatePicker()
        }
        Button("Clean Ignored Files…", role: .destructive) {
          store.presentCleanIgnoredFiles()
        }
        .disabled(!store.canCleanIgnoredFiles)
        Button("Create Worktree…") {
          store.presentCreateWorktree()
        }
        Button("Prune Worktrees") {
          Task { await store.pruneWorktrees() }
        }
        .disabled(store.selectedRepository == nil)
        Divider()
        Button("Add Remote…") {
          store.presentAddRemote()
        }
        Divider()
        Menu("Git LFS") {
          Button("Pull") {
            Task { await store.lfsPull() }
          }
          .disabled(!store.snapshot.integrations.lfsAvailable)
          Button("Fetch") {
            Task { await store.lfsFetch() }
          }
          .disabled(!store.snapshot.integrations.lfsAvailable)
          Button("Checkout Files") {
            Task { await store.lfsCheckout() }
          }
          .disabled(!store.snapshot.integrations.lfsAvailable)
          Button("Prune") {
            Task { await store.lfsPrune() }
          }
          .disabled(!store.snapshot.integrations.lfsAvailable)
          Divider()
          Button("Lock Selected File") {
            Task { await store.lfsLockSelectedFile() }
          }
          .disabled(!store.canRunSelectedFileLFSAction)
          Button("Unlock Selected File") {
            Task { await store.lfsUnlockSelectedFile() }
          }
          .disabled(!store.canRunSelectedFileLFSAction)
          Button("Force Unlock Selected File") {
            Task { await store.lfsUnlockSelectedFile(force: true) }
          }
          .disabled(!store.canRunSelectedFileLFSAction)
        }
        Button(store.snapshot.integrations.gpgSigningEnabled ? "Disable GPG Signing" : "Enable GPG Signing") {
          Task { await store.setCommitSigning(!store.snapshot.integrations.gpgSigningEnabled) }
        }
        Divider()
        Menu("Git-flow") {
          Button("Initialize") {
            Task { await store.initializeGitFlow() }
          }
          .disabled(!store.snapshot.integrations.gitFlowAvailable)
          Divider()
          ForEach(GitFlowStartKind.allCases) { kind in
            Button("Start \(kind.title)…") {
              store.presentGitFlowStart(kind)
            }
            .disabled(!store.snapshot.integrations.gitFlowInitialized)
          }
          ForEach(GitFlowStartKind.allCases) { kind in
            Button("Finish \(kind.title)…") {
              store.presentGitFlowFinish(kind)
            }
            .disabled(!store.snapshot.integrations.gitFlowInitialized)
          }
        }
        Divider()
        Menu("Hosting") {
          Button("Open Current Branch in Browser") {
            store.openCurrentBranchInBrowser()
          }
          .disabled(store.currentBranchWebURL == nil)
          Button("Copy Current Branch Web URL") {
            if let url = store.currentBranchWebURL {
              PasteboardWriter.copy(url.absoluteString)
            }
          }
          .disabled(store.currentBranchWebURL == nil)
          Button("Open Selected Commit in Browser") {
            store.openSelectedCommitInBrowser()
          }
          .disabled(store.selectedCommitWebURL == nil)
          Button("Copy Selected Commit Web URL") {
            if let url = store.selectedCommitWebURL {
              PasteboardWriter.copy(url.absoluteString)
            }
          }
          .disabled(store.selectedCommitWebURL == nil)
          Divider()
          Button("Fetch GitHub Notifications") {
            Task { await store.fetchGitHubNotifications() }
          }
          Button("Mark GitHub Notifications Read") {
            Task { await store.markGitHubNotificationsRead() }
          }
          .disabled(store.gitHubNotifications.isEmpty)
          Divider()
          Button("Create GitHub Repository…") {
            store.presentCreateGitHubRepository()
          }
          Button("Delete GitHub Repository…") {
            store.presentDeleteGitHubRepository()
          }
        }
      }
    } label: {
      ToolbarLabel("Actions", systemImage: "ellipsis.circle", showTitle: showToolbarLabels)
    }
    .help("Repository actions")
  }
}

struct ToolbarLabel: View {
  var title: String
  var systemImage: String
  var showTitle: Bool

  init(_ title: String, systemImage: String, showTitle: Bool) {
    self.title = title
    self.systemImage = systemImage
    self.showTitle = showTitle
  }

  var body: some View {
    if showTitle {
      Label(title, systemImage: systemImage)
        .help(title)
    } else {
      Label(title, systemImage: systemImage)
        .labelStyle(.iconOnly)
        .help(title)
        .accessibilityLabel(title)
    }
  }
}
