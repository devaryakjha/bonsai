import SwiftUI

struct BonsaiCommands: Commands {
  let store: RepositoryStore

  var body: some Commands {
    CommandMenu("Repository") {
      Button("Open Repository...") {
        store.presentOpenRepositoryPanel()
      }
      .keyboardShortcut("o", modifiers: [.command])

      Button("Clone Repository...") {
        store.presentCloneRepository()
      }
      .keyboardShortcut("o", modifiers: [.command, .shift])

      Button("Create Repository...") {
        store.presentCreateRepository()
      }

      Divider()

      Button("Fetch") {
        Task { await store.runRepositoryAction(.fetch) }
      }
      .keyboardShortcut("f", modifiers: [.command])
      .disabled(store.selectedRepository == nil)

      Button("Pull") {
        Task { await store.runRepositoryAction(.pull) }
      }
      .keyboardShortcut("u", modifiers: [.command, .shift])
      .disabled(store.selectedRepository == nil)

      Button("Push") {
        Task { await store.runRepositoryAction(.push) }
      }
      .keyboardShortcut("p", modifiers: [.command, .shift])
      .disabled(store.selectedRepository == nil)

      Divider()

      Button("Refresh") {
        Task { await store.refreshAll() }
      }
      .keyboardShortcut("r", modifiers: [.command])
      .disabled(store.selectedRepository == nil)
    }

    CommandMenu("Git") {
      Button("Create Branch...") {
        store.presentCreateBranch()
      }
      .disabled(store.selectedRepository == nil)

      Button("Create Tag...") {
        store.presentCreateTag()
      }
      .disabled(store.selectedRepository == nil)

      Divider()

      Button("Create Stash...") {
        store.presentStashPush()
      }
      .disabled(store.selectedRepository == nil)

      Button("Create Stash Including Untracked...") {
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
        Task { await store.applyPatchFromClipboard() }
      }
      .disabled(store.selectedRepository == nil)

      Button("Reset to Selected Commit...") {
        store.presentResetToSelectedCommit()
      }
      .disabled(store.selectedRepository == nil || store.selectedCommit == nil)

      Divider()

      Button("Interactive Rebase...") {
        Task { await store.presentInteractiveRebase() }
      }
      .disabled(store.selectedRepository == nil)

      Divider()

      Button("Git LFS Pull") {
        Task { await store.lfsPull() }
      }
      .disabled(store.selectedRepository == nil || !store.snapshot.integrations.lfsAvailable)

      Button("Git LFS Lock Selected File") {
        Task { await store.lfsLockSelectedFile() }
      }
      .disabled(!store.canRunSelectedFileLFSAction)

      Button("Git LFS Unlock Selected File") {
        Task { await store.lfsUnlockSelectedFile() }
      }
      .disabled(!store.canRunSelectedFileLFSAction)

      Button(store.snapshot.integrations.gpgSigningEnabled ? "Disable GPG Signing" : "Enable GPG Signing") {
        Task { await store.setCommitSigning(!store.snapshot.integrations.gpgSigningEnabled) }
      }
      .disabled(store.selectedRepository == nil)

      Divider()

      Button("Initialize Git-flow") {
        Task { await store.initializeGitFlow() }
      }
      .disabled(store.selectedRepository == nil || !store.snapshot.integrations.gitFlowAvailable)

      ForEach(GitFlowStartKind.allCases) { kind in
        Button("Start Git-flow \(kind.title)...") {
          store.presentGitFlowStart(kind)
        }
        .disabled(store.selectedRepository == nil || !store.snapshot.integrations.gitFlowInitialized)
      }

      ForEach(GitFlowStartKind.allCases) { kind in
        Button("Finish Git-flow \(kind.title)...") {
          store.presentGitFlowFinish(kind)
        }
        .disabled(store.selectedRepository == nil || !store.snapshot.integrations.gitFlowInitialized)
      }

      Divider()

      Button("Fetch GitHub Notifications") {
        Task { await store.fetchGitHubNotifications() }
      }

      Button("Mark GitHub Notifications Read") {
        Task { await store.markGitHubNotificationsRead() }
      }
      .disabled(store.gitHubNotifications.isEmpty)

      Button("Create GitHub Repository...") {
        store.presentCreateGitHubRepository()
      }

      Button("Delete GitHub Repository...") {
        store.presentDeleteGitHubRepository()
      }
    }
  }
}
