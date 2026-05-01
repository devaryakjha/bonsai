import SwiftUI

struct SidebarView: View {
  let store: RepositoryStore

  var body: some View {
    List {
      Section("Repository") {
        if let repository = store.selectedRepository {
          Label(repository.name, systemImage: "externaldrive")
            .fontWeight(.semibold)
          Text(repository.path)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        } else {
          Button {
            store.presentOpenRepositoryPanel()
          } label: {
            Label("Open Repository", systemImage: "folder.badge.plus")
          }
        }
      }

      if !store.recentRepositories.isEmpty {
        Section("Recents") {
          ForEach(store.recentRepositories) { repository in
            Button {
              store.openRecent(repository)
            } label: {
              Label(repository.name, systemImage: "clock")
            }
            .buttonStyle(.plain)
          }
        }
      }

      if !store.projectRepositories.isEmpty {
        Section {
          ForEach(store.projectRepositories) { repository in
            Button {
              store.openRecent(repository)
            } label: {
              Label(repository.name, systemImage: "folder")
            }
            .buttonStyle(.plain)
          }
        } header: {
          HStack {
            Text("~/projects")
            Spacer()
            Button {
              store.rescanProjectsDirectory()
            } label: {
              Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Rescan ~/projects")
          }
        }
      }

      Section("Workspace") {
        SidebarMetricRow(title: "Changes", value: store.snapshot.status.count, systemImage: "square.and.pencil")
        SidebarMetricRow(title: "Branches", value: store.localBranches.count, systemImage: "point.3.connected.trianglepath.dotted")
        SidebarMetricRow(title: "Tags", value: store.tags.count, systemImage: "tag")
        SidebarMetricRow(title: "Stashes", value: store.snapshot.stashes.count, systemImage: "tray")
        SidebarMetricRow(title: "Submodules", value: store.snapshot.submodules.count, systemImage: "shippingbox")
      }

      if !store.localBranches.isEmpty {
        Section("Local Branches") {
          ForEach(store.localBranches) { branch in
            HStack {
              Image(systemName: branch.isHead ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(branch.isHead ? .green : .secondary)
                .frame(width: 16)
              Text(branch.shortName)
                .lineLimit(1)
              Spacer()
              if let upstream = branch.upstream {
                Text(upstream)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                }
            }
            .contextMenu {
              Button("Checkout") {
                Task { await store.checkout(branch) }
              }
              Button("Delete") {
                Task { await store.delete(branch) }
              }
              .disabled(branch.isHead)
            }
          }
        }
      }

      if !store.remoteBranches.isEmpty {
        Section("Remote Branches") {
          ForEach(store.remoteBranches.prefix(20)) { branch in
            Label(branch.shortName, systemImage: "network")
              .lineLimit(1)
              .contextMenu {
                Button("Checkout") {
                  Task { await store.checkout(branch) }
                }
              }
          }
        }
      }

      if !store.tags.isEmpty {
        Section("Tags") {
          ForEach(store.tags.prefix(20)) { tag in
            Label(tag.shortName, systemImage: "tag")
              .lineLimit(1)
              .contextMenu {
                Button("Checkout") {
                  Task { await store.checkout(tag) }
                }
                Button("Delete") {
                  Task { await store.delete(tag) }
                }
              }
          }
        }
      }
    }
    .listStyle(.sidebar)
    .overlay {
      if store.isRefreshing {
        ProgressView()
          .controlSize(.small)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
          .padding(.bottom, 12)
      }
    }
  }
}

private struct SidebarMetricRow: View {
  var title: String
  var value: Int
  var systemImage: String

  var body: some View {
    HStack {
      Label(title, systemImage: systemImage)
      Spacer()
      Text(value.formatted())
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }
  }
}
