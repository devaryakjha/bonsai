import SwiftUI

struct RepositoryToolbarActionsMenu: View {
  let store: RepositoryStore
  var showToolbarLabels: Bool

  var body: some View {
    Menu {
      Menu("Branch") {
        Button("Create Branch...") {
          store.presentCreateBranch()
        }
        Button("Create Tag...") {
          store.presentCreateTag()
        }
        Divider()
        Button("Checkout Selected Revision") {
          Task { await store.checkoutSelectedCommit() }
        }
        .disabled(store.selectedCommit == nil)
      }

      Menu("Revision") {
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
        Button("Reset to Selected Commit...") {
          store.presentResetToSelectedCommit()
        }
        .disabled(store.selectedCommit == nil)
        Divider()
        Button("Continue Current Operation") {
          Task { await store.runInProgressOperation(.continueOperation) }
        }
        .disabled(!store.snapshot.inProgressOperation.active)
        Button("Skip Current Operation") {
          Task { await store.runInProgressOperation(.skip) }
        }
        .disabled(!(store.snapshot.inProgressOperation.kind?.canSkip ?? false))
        Button("Abort Current Operation") {
          Task { await store.runInProgressOperation(.abort) }
        }
        .disabled(!store.snapshot.inProgressOperation.active)
        Divider()
        Button("Interactive Rebase...") {
          Task { await store.presentInteractiveRebase() }
        }
        Divider()
        Button("Start Bisect with Selected Commit...") {
          store.presentStartBisect()
        }
        .disabled(store.selectedCommit == nil || store.snapshot.integrations.bisect.active)
        ForEach(GitBisectMark.allCases) { mark in
          Button("Mark Current Commit \(mark.title)") {
            Task { await store.markBisect(mark) }
          }
          .disabled(!store.snapshot.integrations.bisect.active)
        }
        Button("Reset Bisect") {
          Task { await store.resetBisect() }
        }
        .disabled(!store.snapshot.integrations.bisect.active)
      }

      Menu("Stash") {
        Button("Create Stash...") {
          store.presentStashPush()
        }
        Button("Create Stash Including Untracked...") {
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
            Button("Create Branch...") {
              store.presentStashBranch(stash)
            }
            Divider()
            StashCopyMenu(stash: stash)
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
          Task { await store.applyPatchFromClipboard() }
        }
        Button("Open Selected File") {
          store.openSelectedFile()
        }
        .disabled(!store.canOpenSelectedFile)
        Button("Update Submodules") {
          Task { await store.updateSubmodules() }
        }
        Button("Create Worktree...") {
          store.presentCreateWorktree()
        }
        Divider()
        Button("Add Remote...") {
          store.presentAddRemote()
        }
        Divider()
        Menu("Git LFS") {
          Button("Pull") {
            Task { await store.lfsPull() }
          }
          .disabled(!store.snapshot.integrations.lfsAvailable)
          Button("Lock Selected File") {
            Task { await store.lfsLockSelectedFile() }
          }
          .disabled(!store.canRunSelectedFileLFSAction)
          Button("Unlock Selected File") {
            Task { await store.lfsUnlockSelectedFile() }
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
            Button("Start \(kind.title)...") {
              store.presentGitFlowStart(kind)
            }
            .disabled(!store.snapshot.integrations.gitFlowInitialized)
          }
          ForEach(GitFlowStartKind.allCases) { kind in
            Button("Finish \(kind.title)...") {
              store.presentGitFlowFinish(kind)
            }
            .disabled(!store.snapshot.integrations.gitFlowInitialized)
          }
        }
        Divider()
        Menu("GitHub") {
          Button("Fetch Notifications") {
            Task { await store.fetchGitHubNotifications() }
          }
          Button("Mark Notifications Read") {
            Task { await store.markGitHubNotificationsRead() }
          }
          .disabled(store.gitHubNotifications.isEmpty)
          Divider()
          Button("Create Repository...") {
            store.presentCreateGitHubRepository()
          }
          Button("Delete Repository...") {
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
