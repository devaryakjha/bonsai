import SwiftUI

struct MainContentView: View {
  @Bindable var store: RepositoryStore
  let navigationFocus: FocusState<NavigationFocusTarget?>.Binding

  var body: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: InterfaceSpacing.medium) {
        RepositoryStatusStrip(store: store)

        AppKitSegmentedControl(
          options: MainMode.allCases,
          selection: $store.mainMode,
          label: "Main mode",
          title: \.rawValue
        )
      }
      .padding([.horizontal, .top], InterfaceSpacing.panelHorizontal)
      .padding(.bottom, InterfaceSpacing.panelVertical)

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

@MainActor
private struct RepositoryStatusStrip: View {
  let store: RepositoryStore

  var body: some View {
    HStack(spacing: InterfaceSpacing.medium) {
      statusItem(
        systemImage: "arrow.triangle.branch",
        title: branchTitle,
        help: branchHelp
      )

      statusItem(
        systemImage: changeSystemImage,
        title: changeTitle,
        help: changeHelp
      )

      if let trackingTitle {
        statusItem(
          systemImage: "arrow.up.arrow.down",
          title: trackingTitle,
          help: trackingHelp
        )
      }

      Spacer(minLength: InterfaceSpacing.medium)

      statusItem(
        systemImage: store.isRefreshing ? "arrow.clockwise" : "checkmark.circle",
        title: refreshTitle,
        help: refreshHelp
      )
    }
    .font(.bonsaiMetadata)
    .foregroundStyle(.secondary)
    .lineLimit(1)
  }

  private func statusItem(systemImage: String, title: String, help: String) -> some View {
    Label(title, systemImage: systemImage)
      .labelStyle(.titleAndIcon)
      .padding(.horizontal, InterfaceSpacing.medium)
      .padding(.vertical, 3)
      .background(.quaternary.opacity(0.55), in: Capsule())
      .help(help)
      .accessibilityLabel(title)
      .accessibilityHint(help)
  }

  private var branchTitle: String {
    if let branch = store.currentBranch {
      return branch.shortName
    }
    return store.selectedRepository == nil ? "No repository" : "No branch"
  }

  private var branchHelp: String {
    if let branch = store.currentBranch {
      return branch.upstream.map { "Current branch tracks \($0)" } ?? "Current branch has no upstream"
    }
    return store.selectedRepository == nil ? "No repository selected" : "No branch checked out"
  }

  private var changeSystemImage: String {
    store.snapshot.status.isEmpty ? "checkmark.circle" : "square.and.pencil"
  }

  private var changeTitle: String {
    let count = store.snapshot.status.filter { !$0.isIgnored }.count
    guard count > 0 else { return "Clean" }
    return count == 1 ? "1 change" : "\(count.formatted()) changes"
  }

  private var changeHelp: String {
    store.snapshot.status.isEmpty ? "Working tree is clean" : "Working tree has \(changeTitle)"
  }

  private var trackingTitle: String? {
    guard let branch = store.currentBranch else { return nil }
    if branch.upstreamGone {
      return "Upstream gone"
    }
    return branch.trackingSummary
  }

  private var trackingHelp: String {
    guard let branch = store.currentBranch else { return "" }
    if branch.upstreamGone {
      return "Upstream branch is gone"
    }
    if let tracking = branch.trackingSummary {
      return "\(branch.shortName) is \(tracking) from \(branch.upstream ?? "upstream")"
    }
    return "\(branch.shortName) is up to date"
  }

  private var refreshTitle: String {
    if store.isRefreshing {
      return "Refreshing"
    }
    guard let lastRefreshDate = store.lastRefreshDate else {
      return "Not refreshed"
    }
    return "Updated \(StaticDateText.relativeOrDate(lastRefreshDate))"
  }

  private var refreshHelp: String {
    if store.isRefreshing {
      return "Repository refresh is running"
    }
    guard let lastRefreshDate = store.lastRefreshDate else {
      return "Repository has not refreshed in this session"
    }
    return "Last refreshed \(lastRefreshDate.formatted(date: .abbreviated, time: .shortened))"
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
