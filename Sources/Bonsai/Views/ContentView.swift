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
