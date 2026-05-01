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
