import SwiftUI

struct SidebarView: View {
  let store: RepositoryStore
  @AppStorage("bonsai.sidebar.repositoryDetailsExpanded") private var repositoryDetailsExpanded = false
  @AppStorage("bonsai.sidebar.referencesExpanded") private var referencesExpanded = false
  @AppStorage("bonsai.sidebar.advancedExpanded") private var advancedExpanded = false

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

      if !store.projectWorkspaceGroups.isEmpty {
        Section {
          ForEach(store.projectWorkspaceGroups) { group in
            DisclosureGroup {
              ForEach(group.repositories) { repository in
                Button {
                  store.openRecent(repository)
                } label: {
                  Label(repository.name, systemImage: "folder")
                }
                .buttonStyle(.plain)
              }
            } label: {
              HStack {
                Label(group.name, systemImage: "folder")
                Spacer()
                Text(group.repositories.count.formatted())
                  .foregroundStyle(.secondary)
                  .monospacedDigit()
              }
            }
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

      if store.snapshot.inProgressOperation.active {
        Section("Operation") {
          IntegrationRow(
            title: store.snapshot.inProgressOperation.kind?.title ?? "Git",
            detail: "In progress",
            systemImage: "exclamationmark.triangle",
            isEnabled: true
          )
          HStack {
            Button("Continue") {
              Task { await store.runInProgressOperation(.continueOperation) }
            }
            .buttonStyle(.borderless)
            Button("Skip") {
              Task { await store.runInProgressOperation(.skip) }
            }
            .disabled(!(store.snapshot.inProgressOperation.kind?.canSkip ?? false))
            .buttonStyle(.borderless)
            Button("Abort") {
              Task { await store.runInProgressOperation(.abort) }
            }
            .buttonStyle(.borderless)
          }
          .font(.caption)
        }
      }

      if !store.localBranches.isEmpty {
        Section("Local branches") {
          ForEach(store.localBranches) { branch in
            BranchRow(branch: branch)
              .help(branch.upstream.map { "Upstream: \($0)" } ?? "No upstream configured")
            .contextMenu {
              Button("Checkout") {
                Task { await store.checkout(branch) }
              }
              Button("Rename...") {
                store.presentRenameBranch(branch)
              }
              if branch.upstream != nil {
                Button("Unset Upstream") {
                  Task { await store.unsetUpstream(branch) }
                }
              }
              Button("Delete") {
                Task { await store.delete(branch) }
              }
              .disabled(branch.isHead)
            }
          }
        }
      }

      Section("Details") {
        DisclosureGroup(isExpanded: $repositoryDetailsExpanded) {
          repositoryDetailsRows
          integrationRows
        } label: {
          Label("Repository details", systemImage: "info.circle")
        }

        if !store.remoteBranches.isEmpty || !store.tags.isEmpty {
          DisclosureGroup(isExpanded: $referencesExpanded) {
            referenceRows
          } label: {
            Label("Remote branches and tags", systemImage: "tag")
          }
        }

        DisclosureGroup(isExpanded: $advancedExpanded) {
          advancedRows
        } label: {
          Label("Remotes, worktrees and modules", systemImage: "slider.horizontal.3")
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

  @ViewBuilder
  private var repositoryDetailsRows: some View {
    SidebarMetricRow(title: "Changes", value: store.snapshot.status.count, systemImage: "square.and.pencil")
    SidebarMetricRow(title: "Branches", value: store.localBranches.count, systemImage: "point.3.connected.trianglepath.dotted")
    SidebarMetricRow(title: "Remotes", value: store.snapshot.remotes.count, systemImage: "network")
    SidebarMetricRow(title: "Tags", value: store.tags.count, systemImage: "tag")
    SidebarMetricRow(title: "Stashes", value: store.snapshot.stashes.count, systemImage: "tray")
    SidebarMetricRow(title: "Submodules", value: store.snapshot.submodules.count, systemImage: "shippingbox")
    SidebarMetricRow(title: "Worktrees", value: store.snapshot.worktrees.count, systemImage: "square.stack.3d.up")
  }

  @ViewBuilder
  private var integrationRows: some View {
    IntegrationRow(
      title: "Git LFS",
      detail: store.snapshot.integrations.lfsAvailable ? "\(store.snapshot.integrations.lfsFiles.count) files" : "Unavailable",
      systemImage: "externaldrive.connected.to.line.below",
      isEnabled: store.snapshot.integrations.lfsAvailable
    )
    IntegrationRow(
      title: "GPG",
      detail: store.snapshot.integrations.gpgSigningEnabled ? (store.snapshot.integrations.signingKey ?? "Signing on") : "Signing off",
      systemImage: "signature",
      isEnabled: store.snapshot.integrations.gpgSigningEnabled
    )
    IntegrationRow(
      title: "Git-flow",
      detail: gitFlowDetail,
      systemImage: "arrow.triangle.branch",
      isEnabled: store.snapshot.integrations.gitFlowInitialized
    )
    IntegrationRow(
      title: "Bisect",
      detail: store.snapshot.integrations.bisect.detail,
      systemImage: "scope",
      isEnabled: store.snapshot.integrations.bisect.active
    )
    if store.snapshot.integrations.bisect.active {
      HStack {
        ForEach(GitBisectMark.allCases) { mark in
          Button(mark.title) {
            Task { await store.markBisect(mark) }
          }
          .buttonStyle(.borderless)
        }
        Button("Reset") {
          Task { await store.resetBisect() }
        }
        .buttonStyle(.borderless)
      }
      .font(.caption)
    }
    IntegrationRow(
      title: "GitHub",
      detail: store.gitHubNotifications.isEmpty ? "No unread notifications" : "\(store.gitHubNotifications.count) unread",
      systemImage: "bell",
      isEnabled: !store.gitHubNotifications.isEmpty
    )
    if !store.gitHubNotifications.isEmpty {
      Button {
        Task { await store.markGitHubNotificationsRead() }
      } label: {
        Label("Mark read", systemImage: "checkmark.circle")
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  private var referenceRows: some View {
    ForEach(store.remoteBranches.prefix(20)) { branch in
      Label(branch.shortName, systemImage: "network")
        .lineLimit(1)
        .contextMenu {
          Button("Checkout as Local Branch") {
            Task { await store.checkout(branch) }
          }
          Button("Set as Upstream for Current Branch") {
            Task { await store.setCurrentBranchUpstream(branch) }
          }
          .disabled(store.currentBranch == nil)
        }
    }

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

  @ViewBuilder
  private var advancedRows: some View {
    ForEach(store.snapshot.worktrees) { worktree in
      VStack(alignment: .leading, spacing: 2) {
        Label(worktree.name, systemImage: worktree.path == store.selectedRepository?.path ? "checkmark.square" : "square.stack.3d.up")
        Text(worktree.displayState)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
        Text(worktree.path)
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .lineLimit(1)
      }
      .contextMenu {
        Button("Open Worktree") {
          store.openRecent(GitRepository(path: worktree.path))
        }
        Button("Remove Worktree", role: .destructive) {
          Task { await store.removeWorktree(worktree) }
        }
        .disabled(worktree.path == store.selectedRepository?.path)
      }
    }

    if !store.snapshot.worktrees.isEmpty {
      Button {
        store.presentCreateWorktree()
      } label: {
        Label("Create worktree", systemImage: "plus.circle")
      }
      .buttonStyle(.plain)
    }

    ForEach(store.snapshot.submodules) { submodule in
      VStack(alignment: .leading, spacing: 2) {
        Label(submodule.path, systemImage: "shippingbox")
          .lineLimit(1)
        HStack(spacing: 6) {
          Text(submodule.statusTitle)
          Text(submodule.shortCommit)
            .monospaced()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      .contextMenu {
        Button("Open Submodule") {
          store.openSubmodule(submodule)
        }
        Button("Update Submodule") {
          Task { await store.updateSubmodule(submodule) }
        }
      }
    }

    ForEach(store.snapshot.remotes) { remote in
      VStack(alignment: .leading, spacing: 2) {
        Label(remote.name, systemImage: "network")
        Text(remote.fetchURL ?? remote.pushURL ?? "")
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .contextMenu {
        Button("Edit URL") {
          store.presentEditRemote(remote)
        }
        Button("Remove") {
          Task { await store.removeRemote(remote) }
        }
      }
    }

    Button {
      store.presentAddRemote()
    } label: {
      Label("Add remote", systemImage: "plus.circle")
    }
    .buttonStyle(.plain)
  }

  private var gitFlowDetail: String {
    let integrations = store.snapshot.integrations
    if !integrations.gitFlowAvailable {
      return "Unavailable"
    }
    if integrations.gitFlowInitialized {
      return [integrations.gitFlowMainBranch, integrations.gitFlowDevelopBranch]
        .compactMap { $0 }
        .joined(separator: " / ")
    }
    return "Not initialized"
  }
}

private struct BranchRow: View {
  var branch: GitRef

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: branch.isHead ? "checkmark.circle.fill" : "circle")
        .foregroundStyle(branch.isHead ? .green : .secondary)
        .frame(width: 16)
      Text(branch.shortName)
        .lineLimit(1)
      Spacer(minLength: 8)
      if let tracking = branch.trackingSummary {
        Text(tracking)
          .font(.caption2)
          .foregroundStyle(branch.upstreamGone ? .orange : .secondary)
          .padding(.horizontal, 5)
          .padding(.vertical, 2)
          .background(.quaternary, in: Capsule())
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

private struct IntegrationRow: View {
  var title: String
  var detail: String
  var systemImage: String
  var isEnabled: Bool

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: systemImage)
        .foregroundStyle(isEnabled ? .green : .secondary)
        .frame(width: 16)
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
        Text(detail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
  }
}
