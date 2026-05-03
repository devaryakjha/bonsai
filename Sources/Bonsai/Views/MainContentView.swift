import SwiftUI

struct MainContentView: View {
  @Bindable var store: RepositoryStore
  let navigationFocus: FocusState<NavigationFocusTarget?>.Binding

  var body: some View {
    VStack(spacing: 0) {
      AppKitSegmentedControl(
        options: MainMode.allCases,
        selection: $store.mainMode,
        label: "Main mode",
        title: \.rawValue
      )
      .padding([.horizontal, .top], 12)
      .padding(.bottom, 8)

      Divider()

      if store.selectedRepository == nil {
        EmptyRepositoryView(store: store)
      } else {
        switch store.mainMode {
        case .history:
          HistoryView(store: store, navigationFocus: navigationFocus)
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
      BonsaiLogoMark()
        .frame(width: 86, height: 86)
        .accessibilityHidden(true)
      Text("Open a Git repository to begin")
        .font(.title3)
      Button {
        store.presentOpenRepositoryPanel()
      } label: {
        Label("Open repository", systemImage: "folder")
      }
      .buttonStyle(.borderedProminent)

      HStack {
        Button {
          store.presentCloneRepository()
        } label: {
          Label("Clone", systemImage: "square.and.arrow.down")
        }

        Button {
          store.presentCreateRepository()
        } label: {
          Label("Create", systemImage: "plus.square")
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
