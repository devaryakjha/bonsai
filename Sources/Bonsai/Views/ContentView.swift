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
