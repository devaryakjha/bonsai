import SwiftUI

struct MainContentView: View {
  @Bindable var store: RepositoryStore

  var body: some View {
    VStack(spacing: 0) {
      Picker("Mode", selection: $store.mainMode) {
        ForEach(MainMode.allCases) { mode in
          Text(mode.rawValue).tag(mode)
        }
      }
      .pickerStyle(.segmented)
      .padding([.horizontal, .top], 12)
      .padding(.bottom, 8)

      Divider()

      if store.selectedRepository == nil {
        EmptyRepositoryView(store: store)
      } else {
        switch store.mainMode {
        case .history:
          HistoryView(store: store)
        case .changes:
          WorkingTreeView(store: store)
        }
      }
    }
  }
}

private struct EmptyRepositoryView: View {
  let store: RepositoryStore

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "point.3.connected.trianglepath.dotted")
        .font(.system(size: 52))
        .foregroundStyle(.secondary)
      Text("Open a Git repository to begin")
        .font(.title3)
      Button {
        store.presentOpenRepositoryPanel()
      } label: {
        Label("Open Repository", systemImage: "folder")
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
