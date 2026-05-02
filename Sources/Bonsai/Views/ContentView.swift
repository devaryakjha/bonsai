import SwiftUI

struct ContentView: View {
  @Bindable var store: RepositoryStore

  var body: some View {
    NavigationSplitView {
      SidebarView(store: store)
        .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
    } content: {
      MainContentView(store: store)
        .navigationSplitViewColumnWidth(min: 420, ideal: 560)
    } detail: {
      DetailView(store: store)
        .navigationSplitViewColumnWidth(min: 360, ideal: 520)
    }
    .toolbar {
      ToolbarItemGroup {
        Button {
          store.presentOpenRepositoryPanel()
        } label: {
          Label("Open", systemImage: "folder")
        }

        Menu {
          Button("Clone Repository...") {
            store.presentCloneRepository()
          }
          Button("Create Repository...") {
            store.presentCreateRepository()
          }
        } label: {
          Label("New", systemImage: "plus")
        }

        Button {
          Task { await store.refreshAll() }
        } label: {
          Label("Refresh", systemImage: "arrow.clockwise")
        }
        .disabled(store.selectedRepository == nil || store.isRefreshing)
      }

      ToolbarItemGroup {
        Button {
          Task { await store.runRepositoryAction(.fetch) }
        } label: {
          Label("Fetch", systemImage: "arrow.down.circle")
        }
        .disabled(store.selectedRepository == nil)

        Button {
          Task { await store.runRepositoryAction(.pull) }
        } label: {
          Label("Pull", systemImage: "arrow.down.to.line.circle")
        }
        .disabled(store.selectedRepository == nil)

        Button {
          Task { await store.runRepositoryAction(.push) }
        } label: {
          Label("Push", systemImage: "arrow.up.to.line.circle")
        }
        .disabled(store.selectedRepository == nil)
      }

      ToolbarItemGroup {
        Menu {
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
        } label: {
          Label("Branch", systemImage: "point.3.connected.trianglepath.dotted")
        }
        .disabled(store.selectedRepository == nil)

        Menu {
          Button("Cherry-pick Selected Commit") {
            Task { await store.runRevisionCommand("cherry-pick") }
          }
          .disabled(store.selectedCommit == nil)
          Button("Revert Selected Commit") {
            Task { await store.runRevisionCommand("revert") }
          }
          .disabled(store.selectedCommit == nil)
          Button("Merge Selected Commit") {
            Task { await store.runRevisionCommand("merge") }
          }
          .disabled(store.selectedCommit == nil)
          Button("Rebase Onto Selected Commit") {
            Task { await store.runRevisionCommand("rebase") }
          }
          .disabled(store.selectedCommit == nil)
          Button("Reset to Selected Commit...") {
            store.presentResetToSelectedCommit()
          }
          .disabled(store.selectedCommit == nil)
          Divider()
          Button("Interactive Rebase...") {
            Task { await store.presentInteractiveRebase() }
          }
        } label: {
          Label("Actions", systemImage: "bolt")
        }
        .disabled(store.selectedRepository == nil)

        Menu {
          Button("Create Stash...") {
            store.presentStashPush()
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
              Button("Drop") {
                Task { await store.dropStash(stash) }
              }
            }
          }
        } label: {
          Label("Stash", systemImage: "tray")
        }
        .disabled(store.selectedRepository == nil)

        Menu {
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
          Button("Git LFS Pull") {
            Task { await store.lfsPull() }
          }
          .disabled(!store.snapshot.integrations.lfsAvailable)
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
          Divider()
          Button("Initialize Git-flow") {
            Task { await store.initializeGitFlow() }
          }
          .disabled(!store.snapshot.integrations.gitFlowAvailable)
          ForEach(GitFlowStartKind.allCases) { kind in
            Button("Start Git-flow \(kind.title)...") {
              store.presentGitFlowStart(kind)
            }
            .disabled(!store.snapshot.integrations.gitFlowInitialized)
          }
          ForEach(GitFlowStartKind.allCases) { kind in
            Button("Finish Git-flow \(kind.title)...") {
              store.presentGitFlowFinish(kind)
            }
            .disabled(!store.snapshot.integrations.gitFlowInitialized)
          }
          Divider()
          Button("Fetch GitHub Notifications") {
            Task { await store.fetchGitHubNotifications() }
          }
          Button("Mark GitHub Notifications Read") {
            Task { await store.markGitHubNotificationsRead() }
          }
          .disabled(store.gitHubNotifications.isEmpty)
          Divider()
          Button("Create GitHub Repository...") {
            store.presentCreateGitHubRepository()
          }
          Button("Delete GitHub Repository...") {
            store.presentDeleteGitHubRepository()
          }
        } label: {
          Label("Tools", systemImage: "wrench.and.screwdriver")
        }
        .disabled(store.selectedRepository == nil)
      }
    }
    .sheet(item: $store.operationRequest) { request in
      OperationSheet(
        request: request,
        input: $store.operationInput,
        onCancel: {
          store.operationRequest = nil
        },
        onConfirm: {
          Task { await store.confirmOperation() }
        }
      )
    }
    .sheet(item: $store.repositorySetupMode) { mode in
      RepositorySetupSheet(
        mode: mode,
        remoteURL: $store.repositorySetupRemoteURL,
        destinationPath: $store.repositorySetupDestinationPath,
        onRemoteChanged: {
          store.updateCloneDestinationFromRemote()
        },
        onChooseDestination: {
          store.chooseRepositorySetupDestination()
        },
        onCancel: {
          store.repositorySetupMode = nil
        },
        onConfirm: {
          Task { await store.confirmRepositorySetup() }
        }
      )
    }
    .sheet(item: $store.conflictResolutionRequest) { request in
      ConflictResolutionSheet(
        request: request,
        onCancel: {
          store.conflictResolutionRequest = nil
        },
        onResolve: { choice in
          Task { await store.resolveConflict(choice) }
        }
      )
    }
    .sheet(item: $store.discardChangeRequest) { request in
      DiscardChangeSheet(
        request: request,
        onCancel: {
          store.discardChangeRequest = nil
        },
        onDiscard: {
          Task { await store.discardChange() }
        }
      )
    }
    .sheet(isPresented: Binding(
      get: { store.interactiveRebasePlan != nil },
      set: { if !$0 { store.interactiveRebasePlan = nil } }
    )) {
      InteractiveRebaseSheet(
        store: store,
        onCancel: {
          store.interactiveRebasePlan = nil
        },
        onStart: {
          Task { await store.startInteractiveRebase() }
        }
      )
    }
    .sheet(item: $store.resetRequest) { request in
      ResetSheet(
        request: request,
        onCancel: {
          store.resetRequest = nil
        },
        onConfirm: { mode in
          Task { await store.resetToSelectedCommit(mode: mode) }
        }
      )
    }
    .sheet(isPresented: Binding(
      get: { !store.reflogEntries.isEmpty },
      set: { if !$0 { store.reflogEntries = [] } }
    )) {
      ReflogSheet(
        entries: store.reflogEntries,
        onCancel: {
          store.reflogEntries = []
        },
        onCheckout: { entry in
          Task { await store.checkoutReflogEntry(entry) }
        },
        onReset: { entry in
          store.presentResetToReflogEntry(entry)
        }
      )
    }
    .sheet(item: $store.blameDocument) { document in
      BlameSheet(
        document: document,
        onCancel: {
          store.blameDocument = nil
        },
        onSelectCommit: { line in
          Task { await store.focusCommit(hash: line.commitHash) }
        }
      )
    }
    .sheet(item: $store.fileHistoryDocument) { document in
      FileHistorySheet(
        document: document,
        onCancel: {
          store.fileHistoryDocument = nil
        },
        onSelectCommit: { entry in
          Task { await store.focusCommit(hash: entry.hash) }
        }
      )
    }
    .sheet(item: $store.reflogResetRequest) { request in
      ReflogResetSheet(
        request: request,
        onCancel: {
          store.reflogResetRequest = nil
        },
        onConfirm: { mode in
          Task { await store.resetToReflogEntry(mode: mode) }
        }
      )
    }
    .sheet(item: $store.remoteEditorRequest) { request in
      RemoteEditorSheet(
        request: request,
        onCancel: {
          store.remoteEditorRequest = nil
        },
        onSave: { name, url in
          Task { await store.saveRemote(name: name, url: url) }
        }
      )
    }
    .sheet(item: $store.gitHubRepositoryRequest) { request in
      GitHubRepositorySheet(
        request: request,
        onCancel: {
          store.gitHubRepositoryRequest = nil
        },
        onConfirm: { updatedRequest in
          Task { await store.runGitHubRepositoryOperation(updatedRequest) }
        }
      )
    }
    .task {
      await store.refreshAll()
    }
    .alert("Bonsai", isPresented: Binding(
      get: { store.errorMessage != nil },
      set: { if !$0 { store.errorMessage = nil } }
    )) {
      Button("OK") {
        store.errorMessage = nil
      }
    } message: {
      Text(store.errorMessage ?? "")
    }
  }
}

private struct FileHistorySheet: View {
  var document: GitFileHistoryDocument
  var onCancel: () -> Void
  var onSelectCommit: (GitFileHistoryEntry) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text("File History")
            .font(.title3)
            .fontWeight(.semibold)
          Text(document.path)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer()
        Button("Close", action: onCancel)
      }

      List(document.entries) { entry in
        FileHistoryRow(entry: entry, onSelectCommit: onSelectCommit)
      }
      .listStyle(.inset)
      .frame(minHeight: 420)
    }
    .padding(20)
    .frame(minWidth: 840, minHeight: 540)
  }
}

private struct FileHistoryRow: View {
  var entry: GitFileHistoryEntry
  var onSelectCommit: (GitFileHistoryEntry) -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Button {
        onSelectCommit(entry)
      } label: {
        Image(systemName: "arrow.right.circle")
      }
      .buttonStyle(.borderless)
      .help("Show commit")

      Text(entry.shortHash)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .frame(width: 72, alignment: .leading)
        .textSelection(.enabled)

      VStack(alignment: .leading, spacing: 6) {
        Text(entry.subject)
          .lineLimit(1)
          .textSelection(.enabled)

        HStack(spacing: 8) {
          Text(entry.authorName)
            .lineLimit(1)
            .help(entry.authorEmail)
          if let date = entry.date {
            Text(date, style: .date)
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        if !entry.changes.isEmpty {
          ScrollView(.horizontal) {
            HStack(spacing: 6) {
              ForEach(entry.changes) { change in
                FileChangePill(change: change)
              }
            }
          }
          .scrollIndicators(.hidden)
        }
      }
    }
    .padding(.vertical, 5)
  }
}

private struct FileChangePill: View {
  var change: GitChangedFile

  var body: some View {
    HStack(spacing: 5) {
      Text(change.status)
        .font(.caption2.monospaced().weight(.semibold))
        .foregroundStyle(.secondary)
      Text(change.oldPath.map { "\($0) -> \(change.path)" } ?? change.path)
        .font(.caption.monospaced())
        .lineLimit(1)
    }
    .padding(.horizontal, 7)
    .padding(.vertical, 3)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
  }
}

private struct BlameSheet: View {
  var document: GitBlameDocument
  var onCancel: () -> Void
  var onSelectCommit: (GitBlameLine) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text("Blame")
            .font(.title3)
            .fontWeight(.semibold)
          Text(document.path)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer()
        Button("Close", action: onCancel)
      }

      ScrollView([.horizontal, .vertical]) {
        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
          Section {
            ForEach(document.lines) { line in
              BlameRow(line: line, onSelectCommit: onSelectCommit)
              Divider()
            }
          } header: {
            BlameHeaderRow()
              .background(.regularMaterial)
          }
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .stroke(.quaternary)
      }
    }
    .padding(20)
    .frame(minWidth: 900, minHeight: 560)
  }
}

private struct BlameHeaderRow: View {
  var body: some View {
    HStack(spacing: 12) {
      Text("")
        .frame(width: 22)
      Text("Line")
        .frame(width: 52, alignment: .trailing)
      Text("Commit")
        .frame(width: 72, alignment: .leading)
      Text("Author")
        .frame(width: 160, alignment: .leading)
      Text("Date")
        .frame(width: 132, alignment: .leading)
      Text("Content")
        .frame(minWidth: 360, alignment: .leading)
    }
    .font(.caption.weight(.semibold))
    .foregroundStyle(.secondary)
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
  }
}

private struct BlameRow: View {
  var line: GitBlameLine
  var onSelectCommit: (GitBlameLine) -> Void

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Button {
        onSelectCommit(line)
      } label: {
        Image(systemName: "arrow.right.circle")
      }
      .buttonStyle(.borderless)
      .help("Show commit")
      .frame(width: 22)

      Text("\(line.finalLine)")
        .foregroundStyle(.secondary)
        .frame(width: 52, alignment: .trailing)

      Text(line.shortHash)
        .foregroundStyle(.secondary)
        .frame(width: 72, alignment: .leading)
        .textSelection(.enabled)

      Text(line.author.isEmpty ? "Unknown" : line.author)
        .frame(width: 160, alignment: .leading)
        .lineLimit(1)
        .help(line.authorMail ?? line.author)

      Text(dateText)
        .foregroundStyle(.secondary)
        .frame(width: 132, alignment: .leading)

      Text(line.content.isEmpty ? " " : line.content)
        .frame(minWidth: 360, alignment: .leading)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .textSelection(.enabled)
    }
    .font(.caption.monospaced())
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
  }

  private var dateText: String {
    line.authorTime?.formatted(date: .abbreviated, time: .shortened) ?? "-"
  }
}

private struct DiscardChangeSheet: View {
  var request: DiscardChangeRequest
  var onCancel: () -> Void
  var onDiscard: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Discard Change")
        .font(.title3)
        .fontWeight(.semibold)

      Text(request.entry.path)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.entry.isUntracked ? "This will remove the untracked file." : "This will restore the file from Git and discard local edits.")
        .foregroundStyle(.secondary)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Discard", role: .destructive, action: onDiscard)
          .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 460)
  }
}

private struct GitHubRepositorySheet: View {
  var request: GitHubRepositoryRequest
  var onCancel: () -> Void
  var onConfirm: (GitHubRepositoryRequest) -> Void
  @State private var owner: String
  @State private var name: String
  @State private var description: String
  @State private var isPrivate: Bool

  init(
    request: GitHubRepositoryRequest,
    onCancel: @escaping () -> Void,
    onConfirm: @escaping (GitHubRepositoryRequest) -> Void
  ) {
    self.request = request
    self.onCancel = onCancel
    self.onConfirm = onConfirm
    _owner = State(initialValue: request.owner)
    _name = State(initialValue: request.name)
    _description = State(initialValue: request.repositoryDescription)
    _isPrivate = State(initialValue: request.isPrivate)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.operation.title)
        .font(.title3)
        .fontWeight(.semibold)

      if request.operation == .delete {
        Text("Deletion is permanent and requires a token with repository deletion permissions.")
          .foregroundStyle(.secondary)
      }

      if request.operation == .delete {
        TextField("Owner", text: $owner)
          .textFieldStyle(.roundedBorder)
      }

      TextField("Repository name", text: $name)
        .textFieldStyle(.roundedBorder)

      if request.operation == .create {
        TextField("Description", text: $description)
          .textFieldStyle(.roundedBorder)
        Toggle("Private", isOn: $isPrivate)
      }

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button(request.operation.primaryActionTitle) {
          onConfirm(GitHubRepositoryRequest(
            operation: request.operation,
            owner: owner,
            name: name,
            repositoryDescription: description,
            isPrivate: isPrivate
          ))
        }
        .buttonStyle(.borderedProminent)
        .disabled(!canConfirm)
      }
    }
    .padding(20)
    .frame(width: 520)
  }

  private var canConfirm: Bool {
    let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    if request.operation == .delete {
      return hasName && !owner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    return hasName
  }
}

private struct RemoteEditorSheet: View {
  var request: RemoteEditorRequest
  var onCancel: () -> Void
  var onSave: (String, String) -> Void
  @State private var name: String
  @State private var url: String

  init(request: RemoteEditorRequest, onCancel: @escaping () -> Void, onSave: @escaping (String, String) -> Void) {
    self.request = request
    self.onCancel = onCancel
    self.onSave = onSave
    _name = State(initialValue: request.name)
    _url = State(initialValue: request.url)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.mode.title)
        .font(.title3)
        .fontWeight(.semibold)

      TextField("Name", text: $name)
        .textFieldStyle(.roundedBorder)
        .disabled(request.mode == .edit)

      TextField("URL", text: $url)
        .textFieldStyle(.roundedBorder)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button(request.mode.primaryActionTitle) {
          onSave(name, url)
        }
        .buttonStyle(.borderedProminent)
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .padding(20)
    .frame(width: 520)
  }
}

private struct ResetSheet: View {
  var request: ResetRequest
  var onCancel: () -> Void
  var onConfirm: (ResetMode) -> Void
  @State private var mode: ResetMode = .mixed

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Reset Branch")
        .font(.title3)
        .fontWeight(.semibold)

      Text("Reset the current branch to \(request.commit.shortHash). Hard reset discards working tree changes.")
        .foregroundStyle(.secondary)

      Picker("Mode", selection: $mode) {
        ForEach(ResetMode.allCases) { mode in
          Text(mode.title).tag(mode)
        }
      }
      .pickerStyle(.segmented)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Reset") {
          onConfirm(mode)
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 460)
  }
}

private struct ReflogResetSheet: View {
  var request: ReflogResetRequest
  var onCancel: () -> Void
  var onConfirm: (ResetMode) -> Void
  @State private var mode: ResetMode = .mixed

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Reset to Reflog Entry")
        .font(.title3)
        .fontWeight(.semibold)

      Text("\(request.entry.selector) \(request.entry.shortHash)")
        .font(.body.monospaced())

      Text("Hard reset discards working tree changes.")
        .foregroundStyle(.secondary)

      Picker("Mode", selection: $mode) {
        ForEach(ResetMode.allCases) { mode in
          Text(mode.title).tag(mode)
        }
      }
      .pickerStyle(.segmented)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Reset") {
          onConfirm(mode)
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 480)
  }
}

private struct ReflogSheet: View {
  var entries: [GitReflogEntry]
  var onCancel: () -> Void
  var onCheckout: (GitReflogEntry) -> Void
  var onReset: (GitReflogEntry) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Reflog")
          .font(.title3)
          .fontWeight(.semibold)
        Spacer()
        Button("Close", action: onCancel)
      }

      Text("Recover a previous HEAD by checking it out or resetting the current branch.")
        .foregroundStyle(.secondary)

      List(entries) { entry in
        HStack(spacing: 10) {
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text(entry.selector)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
              Text(entry.shortHash)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            }
            Text(entry.subject)
              .lineLimit(1)
            if let date = entry.date {
              Text(date, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }

          Spacer()

          Button("Checkout") {
            onCheckout(entry)
          }
          .buttonStyle(.borderless)

          Button("Reset...") {
            onReset(entry)
          }
          .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
      }
      .frame(minHeight: 360)
    }
    .padding(20)
    .frame(minWidth: 720, minHeight: 480)
  }
}

private struct InteractiveRebaseSheet: View {
  let store: RepositoryStore
  var onCancel: () -> Void
  var onStart: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Interactive Rebase")
        .font(.title3)
        .fontWeight(.semibold)

      Text("Edit the todo plan before Git starts the rebase.")
        .foregroundStyle(.secondary)

      if let plan = store.interactiveRebasePlan {
        VStack(spacing: 0) {
          ForEach(plan.items) { item in
            InteractiveRebaseRow(
              item: item,
              canMoveUp: plan.items.first?.id != item.id,
              canMoveDown: plan.items.last?.id != item.id,
              onActionChanged: { action in
                store.setRebaseAction(action, for: item)
              },
              onMoveUp: {
                store.moveRebaseItem(item, direction: -1)
              },
              onMoveDown: {
                store.moveRebaseItem(item, direction: 1)
              }
            )
            Divider()
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
          RoundedRectangle(cornerRadius: 8)
            .stroke(.quaternary)
        }

        Text(plan.todoText)
          .font(.caption.monospaced())
          .foregroundStyle(.secondary)
          .lineLimit(6)
          .textSelection(.enabled)
      }

      HStack {
        Button("Cancel", action: onCancel)
        Spacer()
        Button("Start Rebase", action: onStart)
          .buttonStyle(.borderedProminent)
          .disabled(store.interactiveRebasePlan?.items.isEmpty != false)
      }
    }
    .padding(20)
    .frame(minWidth: 760)
  }
}

private struct InteractiveRebaseRow: View {
  var item: InteractiveRebaseItem
  var canMoveUp: Bool
  var canMoveDown: Bool
  var onActionChanged: (RebaseTodoAction) -> Void
  var onMoveUp: () -> Void
  var onMoveDown: () -> Void

  var body: some View {
    HStack(spacing: 10) {
      Picker("Action", selection: Binding(
        get: { item.action },
        set: onActionChanged
      )) {
        ForEach(RebaseTodoAction.allCases) { action in
          Text(action.title).tag(action)
        }
      }
      .labelsHidden()
      .frame(width: 116)

      Text(item.shortHash)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .frame(width: 72, alignment: .leading)

      Text(item.subject)
        .lineLimit(1)

      Spacer()

      Button {
        onMoveUp()
      } label: {
        Image(systemName: "chevron.up")
      }
      .disabled(!canMoveUp)
      .buttonStyle(.borderless)
      .help("Move up")

      Button {
        onMoveDown()
      } label: {
        Image(systemName: "chevron.down")
      }
      .disabled(!canMoveDown)
      .buttonStyle(.borderless)
      .help("Move down")
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
  }
}

private struct ConflictResolutionSheet: View {
  var request: ConflictResolutionRequest
  var onCancel: () -> Void
  var onResolve: (ConflictResolutionChoice) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Resolve Conflict")
        .font(.title3)
        .fontWeight(.semibold)

      Text(request.entry.path)
        .foregroundStyle(.secondary)
        .lineLimit(1)

      RichDiffTextView(text: request.preview)
        .frame(minWidth: 720, minHeight: 420)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
          RoundedRectangle(cornerRadius: 8)
            .stroke(.quaternary)
        }

      HStack {
        Button("Cancel", action: onCancel)
        Spacer()
        Button(ConflictResolutionChoice.ours.rawValue) {
          onResolve(.ours)
        }
        Button(ConflictResolutionChoice.theirs.rawValue) {
          onResolve(.theirs)
        }
        Button(ConflictResolutionChoice.markResolved.rawValue) {
          onResolve(.markResolved)
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
  }
}

private struct RepositorySetupSheet: View {
  var mode: RepositorySetupMode
  @Binding var remoteURL: String
  @Binding var destinationPath: String
  var onRemoteChanged: () -> Void
  var onChooseDestination: () -> Void
  var onCancel: () -> Void
  var onConfirm: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(mode.title)
        .font(.title3)
        .fontWeight(.semibold)

      if mode == .clone {
        VStack(alignment: .leading, spacing: 6) {
          Text("Remote URL")
            .font(.caption)
            .foregroundStyle(.secondary)
          TextField("git@github.com:owner/repository.git", text: $remoteURL)
            .textFieldStyle(.roundedBorder)
            .onSubmit(onRemoteChanged)
            .onChange(of: remoteURL) { _, _ in onRemoteChanged() }
        }
      }

      VStack(alignment: .leading, spacing: 6) {
        Text(mode == .clone ? "Destination" : "Repository Folder")
          .font(.caption)
          .foregroundStyle(.secondary)
        HStack {
          TextField("~/projects/repository", text: $destinationPath)
            .textFieldStyle(.roundedBorder)
          Button {
            onChooseDestination()
          } label: {
            Image(systemName: "folder")
          }
          .help("Choose folder")
        }
      }

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button(mode.primaryActionTitle, action: onConfirm)
          .buttonStyle(.borderedProminent)
          .disabled(!canConfirm)
      }
    }
    .padding(20)
    .frame(width: 520)
  }

  private var canConfirm: Bool {
    let hasDestination = !destinationPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    if mode == .clone {
      return hasDestination && !remoteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    return hasDestination
  }
}

private struct OperationSheet: View {
  var request: GitOperationRequest
  @Binding var input: String
  var onCancel: () -> Void
  var onConfirm: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.title3)
        .fontWeight(.semibold)

      Text(request.message)
        .foregroundStyle(.secondary)

      TextField(request.placeholder, text: $input)
        .textFieldStyle(.roundedBorder)
        .onAppear {
          input = request.defaultValue
        }

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button(request.primaryActionTitle, action: onConfirm)
          .buttonStyle(.borderedProminent)
          .disabled(request.kind != .stashPush && input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .padding(20)
    .frame(width: 420)
  }
}
