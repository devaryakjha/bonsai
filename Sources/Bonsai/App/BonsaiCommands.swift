import SwiftUI

struct BonsaiCommands: Commands {
  let store: RepositoryStore
  @AppStorage("bonsai.showCommitRowDetails") private var showCommitRowDetails = false

  var body: some Commands {
    CommandGroup(after: .sidebar) {
      Button(showCommitRowDetails ? "Hide Commit Details" : "Show Commit Details") {
        showCommitRowDetails.toggle()
      }
      .keyboardShortcut("d", modifiers: [.command])

      Divider()
    }

    CommandMenu("Repository") {
      Button("Open Repository…") {
        store.presentOpenRepositoryPanel()
      }
      .keyboardShortcut("o", modifiers: [.command])

      Button("Clone Repository…") {
        store.presentCloneRepository()
      }
      .keyboardShortcut("o", modifiers: [.command, .shift])

      Button("Create Repository…") {
        store.presentCreateRepository()
      }

      Button("Clear Recent Repositories") {
        store.clearRecentRepositories()
      }
      .disabled(store.recentRepositories.isEmpty)

      Divider()

      Button("Copy Repository Path") {
        store.copyRepositoryPath()
      }
      .disabled(store.selectedRepository == nil)

      Button("Reveal in Finder") {
        store.revealRepositoryInFinder()
      }
      .disabled(store.selectedRepository == nil)

      Button("Open in Terminal") {
        store.openRepositoryInTerminal()
      }
      .disabled(store.selectedRepository == nil)

      Divider()

      Button("Fetch") {
        Task { await store.runRepositoryAction(.fetch) }
      }
      .keyboardShortcut("f", modifiers: [.command, .shift])
      .disabled(store.selectedRepository == nil)

      Button(store.currentBranch?.pullTitle ?? "Pull") {
        Task { await store.runRepositoryAction(.pull) }
      }
      .keyboardShortcut("u", modifiers: [.command, .shift])
      .disabled(store.selectedRepository == nil || !store.canPull)

      Button(store.pushActionTitle) {
        Task { await store.runRepositoryAction(.push) }
      }
      .keyboardShortcut("p", modifiers: [.command, .shift])
      .disabled(store.selectedRepository == nil || !store.canPush)

      Button("Force Push with Lease…") {
        store.presentForcePushCurrentBranch()
      }
      .disabled(store.selectedRepository == nil || !store.canForcePushCurrentBranch)

      Divider()

      Button("Refresh") {
        Task { await store.refreshAll() }
      }
      .keyboardShortcut("r", modifiers: [.command])
      .disabled(store.selectedRepository == nil)
    }

    CommandMenu("Git") {
      Button(store.amendCommit ? "Amend Commit" : "Commit") {
        Task { await store.commit() }
      }
      .keyboardShortcut(.return, modifiers: [.command])
      .disabled(store.selectedRepository == nil || !store.canCommit)

      Button("Stage Selected File") {
        Task { await store.stageSelectedStatusEntry() }
      }
      .disabled(store.selectedRepository == nil || !store.canStageSelectedStatusEntry)

      Button("Unstage Selected File") {
        Task { await store.unstageSelectedStatusEntry() }
      }
      .disabled(store.selectedRepository == nil || !store.canUnstageSelectedStatusEntry)

      Button("Ignore Selected File") {
        Task { await store.ignoreSelectedStatusEntry() }
      }
      .disabled(store.selectedRepository == nil || !store.canIgnoreSelectedStatusEntry)

      Button("Ignore Selected File Extension") {
        Task { await store.ignoreSelectedStatusEntryExtension() }
      }
      .disabled(store.selectedRepository == nil || !store.canIgnoreSelectedStatusEntryExtension)

      Button("Ignore Selected File Folder") {
        Task { await store.ignoreSelectedStatusEntryDirectory() }
      }
      .disabled(store.selectedRepository == nil || !store.canIgnoreSelectedStatusEntryDirectory)

      Button("Add .gitignore Template…") {
        store.presentGitIgnoreTemplatePicker()
      }
      .disabled(store.selectedRepository == nil)

      Button("Stage All") {
        Task { await store.stageAll() }
      }
      .disabled(store.selectedRepository == nil || !store.canStageAll)

      Button("Unstage All") {
        Task { await store.unstageAll() }
      }
      .disabled(store.selectedRepository == nil || !store.canUnstageAll)

      Divider()

      Button("Create Branch…") {
        store.presentCreateBranch()
      }
      .disabled(store.selectedRepository == nil)

      Button("Create Tag…") {
        store.presentCreateTag()
      }
      .disabled(store.selectedRepository == nil)

      Button("Create Annotated Tag…") {
        store.presentCreateAnnotatedTag()
      }
      .disabled(store.selectedRepository == nil)

      Button("Create Worktree…") {
        store.presentCreateWorktree()
      }
      .disabled(store.selectedRepository == nil)

      Button("Prune Worktrees") {
        Task { await store.pruneWorktrees() }
      }
      .disabled(store.selectedRepository == nil)

      Divider()

      Button("Create Stash…") {
        store.presentStashPush()
      }
      .disabled(store.selectedRepository == nil)

      Button("Create Stash Including Untracked…") {
        store.presentStashPush(includeUntracked: true)
      }
      .disabled(store.selectedRepository == nil)

      Button("Show Reflog") {
        Task { await store.showReflog() }
      }
      .disabled(store.selectedRepository == nil)

      Button("Copy Current Patch") {
        store.copyCurrentPatch()
      }
      .disabled(!store.canCopyCurrentPatch)

      Button("Apply Patch from Clipboard") {
        store.presentApplyPatchFromClipboard()
      }
      .disabled(store.selectedRepository == nil)

      Button("Open Selected File") {
        store.openSelectedFile()
      }
      .disabled(!store.canOpenSelectedFile)

      Button("Reset to Selected Commit…") {
        store.presentResetToSelectedCommit()
      }
      .disabled(store.selectedRepository == nil || store.selectedCommit == nil)

      Divider()

      Button("Continue Current Operation") {
        Task { await store.runInProgressOperation(.continueOperation) }
      }
      .disabled(store.selectedRepository == nil || !store.snapshot.inProgressOperation.active)

      Button("Skip Current Operation") {
        Task { await store.runInProgressOperation(.skip) }
      }
      .disabled(store.selectedRepository == nil || !(store.snapshot.inProgressOperation.kind?.canSkip ?? false))

      Button("Abort Current Operation") {
        Task { await store.runInProgressOperation(.abort) }
      }
      .disabled(store.selectedRepository == nil || !store.snapshot.inProgressOperation.active)

      Divider()

      Button("Interactive Rebase…") {
        Task { await store.presentInteractiveRebase() }
      }
      .disabled(store.selectedRepository == nil)

      Button("Start Bisect with Selected Commit…") {
        store.presentStartBisect()
      }
      .disabled(store.selectedRepository == nil || store.selectedCommit == nil || store.snapshot.integrations.bisect.active)

      ForEach(GitBisectMark.allCases) { mark in
        Button("Mark Current Commit \(mark.title)") {
          Task { await store.markBisect(mark) }
        }
        .disabled(store.selectedRepository == nil || !store.snapshot.integrations.bisect.active)
      }

      Button("Reset Bisect") {
        Task { await store.resetBisect() }
      }
      .disabled(store.selectedRepository == nil || !store.snapshot.integrations.bisect.active)

      Divider()

      Menu("Git LFS") {
        Button("Pull") {
          Task { await store.lfsPull() }
        }
        .disabled(store.selectedRepository == nil || !store.snapshot.integrations.lfsAvailable)

        Button("Fetch") {
          Task { await store.lfsFetch() }
        }
        .disabled(store.selectedRepository == nil || !store.snapshot.integrations.lfsAvailable)

        Button("Checkout Files") {
          Task { await store.lfsCheckout() }
        }
        .disabled(store.selectedRepository == nil || !store.snapshot.integrations.lfsAvailable)

        Button("Prune") {
          Task { await store.lfsPrune() }
        }
        .disabled(store.selectedRepository == nil || !store.snapshot.integrations.lfsAvailable)

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
      .disabled(store.selectedRepository == nil)

      Divider()

      Menu("Git-flow") {
        Button("Initialize") {
          Task { await store.initializeGitFlow() }
        }
        .disabled(store.selectedRepository == nil || !store.snapshot.integrations.gitFlowAvailable)

        Divider()

        ForEach(GitFlowStartKind.allCases) { kind in
          Button("Start \(kind.title)…") {
            store.presentGitFlowStart(kind)
          }
          .disabled(store.selectedRepository == nil || !store.snapshot.integrations.gitFlowInitialized)
        }

        ForEach(GitFlowStartKind.allCases) { kind in
          Button("Finish \(kind.title)…") {
            store.presentGitFlowFinish(kind)
          }
          .disabled(store.selectedRepository == nil || !store.snapshot.integrations.gitFlowInitialized)
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
  }
}
