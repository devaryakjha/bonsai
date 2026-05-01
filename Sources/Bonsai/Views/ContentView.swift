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
          Button("Update Submodules") {
            Task { await store.updateSubmodules() }
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
