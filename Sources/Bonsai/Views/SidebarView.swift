import SwiftUI

struct SidebarView: View {
  let store: RepositoryStore
  @AppStorage("bonsai.sidebar.repositoryDetailsExpanded") private var repositoryDetailsExpanded = false
  @AppStorage("bonsai.sidebar.referencesExpanded") private var referencesExpanded = false
  @AppStorage("bonsai.sidebar.worktreesExpanded") private var worktreesExpanded = false
  @AppStorage("bonsai.sidebar.remotesExpanded") private var remotesExpanded = false
  @AppStorage("bonsai.sidebar.submodulesExpanded") private var submodulesExpanded = false
  @AppStorage("bonsai.sidebar.lfsFilesExpanded") private var lfsFilesExpanded = false

  var body: some View {
    List {
      Section("Repository") {
        if let repository = store.selectedRepository {
          RepositoryHeaderRow(
            repository: repository,
            detail: repositoryHeaderDetail,
            path: repository.path
          )
            .contextMenu {
              Button("Copy Path") {
                store.copyRepositoryPath()
              }
              Button("Reveal in Finder") {
                store.revealRepositoryInFinder()
              }
            }
        } else {
          Button {
            store.presentOpenRepositoryPanel()
          } label: {
            Label("Open repository", systemImage: "folder.badge.plus")
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
            .help(repository.path)
            .contextMenu {
              Button("Copy Path") {
                store.copyRepositoryPath(repository)
              }
              Button("Reveal in Finder") {
                store.revealRepositoryInFinder(repository)
              }
              Divider()
              Button("Remove from Recents", role: .destructive) {
                store.removeRecentRepository(repository)
              }
            }
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
              Button("Create Branch from Here...") {
                store.presentCreateBranch(from: branch)
              }
              Button("Create Tag Here...") {
                store.presentCreateTag(from: branch)
              }
              Button("Rename...") {
                store.presentRenameBranch(branch)
              }
              if branch.upstream != nil {
                Button("Unset Upstream") {
                  Task { await store.unsetUpstream(branch) }
                }
              }
              Divider()
              ReferenceCopyMenu(ref: branch)
              Divider()
              Button("Delete", role: .destructive) {
                store.presentDelete(branch)
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
          lfsRows
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

        DisclosureGroup(isExpanded: $worktreesExpanded) {
          worktreeRows
        } label: {
          SidebarDisclosureLabel(title: "Worktrees", count: store.snapshot.worktrees.count, systemImage: "square.stack.3d.up")
        }

        DisclosureGroup(isExpanded: $remotesExpanded) {
          remoteRows
        } label: {
          SidebarDisclosureLabel(title: "Remotes", count: store.snapshot.remotes.count, systemImage: "network")
        }

        if !store.snapshot.submodules.isEmpty {
          DisclosureGroup(isExpanded: $submodulesExpanded) {
            submoduleRows
          } label: {
            SidebarDisclosureLabel(title: "Submodules", count: store.snapshot.submodules.count, systemImage: "shippingbox")
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
  private var lfsRows: some View {
    if store.snapshot.integrations.lfsAvailable && !store.snapshot.integrations.lfsFiles.isEmpty {
      DisclosureGroup(isExpanded: $lfsFilesExpanded) {
        ForEach(store.snapshot.integrations.lfsFiles) { file in
          LFSFileSidebarRow(file: file)
            .contextMenu {
              Button("Copy Path") {
                PasteboardWriter.copy(file.path)
              }
              Button("Copy Object ID") {
                PasteboardWriter.copy(file.oid)
              }
              Divider()
              Button("Lock") {
                Task { await store.lfsLock(file) }
              }
              Button("Unlock") {
                Task { await store.lfsUnlock(file) }
              }
            }
        }
      } label: {
        SidebarDisclosureLabel(
          title: "Git LFS files",
          count: store.snapshot.integrations.lfsFiles.count,
          systemImage: "externaldrive.connected.to.line.below"
        )
      }
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
          Button("Create Branch from Here...") {
            store.presentCreateBranch(from: branch)
          }
          Button("Create Tag Here...") {
            store.presentCreateTag(from: branch)
          }
          Button("Set as Upstream for Current Branch") {
            Task { await store.setCurrentBranchUpstream(branch) }
          }
          .disabled(store.currentBranch == nil)
          Divider()
          ReferenceCopyMenu(ref: branch)
          Divider()
          Button("Delete", role: .destructive) {
            store.presentDelete(branch)
          }
        }
    }

    ForEach(store.tags.prefix(20)) { tag in
      Label(tag.shortName, systemImage: "tag")
        .lineLimit(1)
        .contextMenu {
          Button("Checkout") {
            Task { await store.checkout(tag) }
          }
          Button("Create Branch from Here...") {
            store.presentCreateBranch(from: tag)
          }
          Divider()
          ReferenceCopyMenu(ref: tag)
          Divider()
          Button("Delete", role: .destructive) {
            store.presentDelete(tag)
          }
        }
    }
  }

  @ViewBuilder
  private var worktreeRows: some View {
    ForEach(store.snapshot.worktrees) { worktree in
      WorktreeSidebarRow(worktree: worktree, isCurrent: worktree.path == store.selectedRepository?.path)
      .contextMenu {
        Button("Open Worktree") {
          store.openRecent(GitRepository(path: worktree.path))
        }
        Button("Copy Path") {
          PasteboardWriter.copy(worktree.path)
        }
        Button("Remove Worktree", role: .destructive) {
          store.presentRemoveWorktree(worktree)
        }
        .disabled(worktree.path == store.selectedRepository?.path)
      }
    }

    Button {
      store.presentCreateWorktree()
    } label: {
      SidebarInlineAction(title: "Create worktree", systemImage: "plus.circle")
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var remoteRows: some View {
    ForEach(store.snapshot.remotes) { remote in
      RemoteSidebarRow(remote: remote)
      .contextMenu {
        Button("Fetch") {
          Task { await store.fetchRemote(remote) }
        }
        if let fetchURL = remote.fetchURL {
          Button("Copy Fetch URL") {
            PasteboardWriter.copy(fetchURL)
          }
        }
        if let pushURL = remote.pushURL {
          Button("Copy Push URL") {
            PasteboardWriter.copy(pushURL)
          }
        }
        Button("Edit URL") {
          store.presentEditRemote(remote)
        }
        Button("Remove", role: .destructive) {
          store.presentRemoveRemote(remote)
        }
      }
    }

    Button {
      store.presentAddRemote()
    } label: {
      SidebarInlineAction(title: "Add remote", systemImage: "plus.circle")
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var submoduleRows: some View {
    ForEach(store.snapshot.submodules) { submodule in
      SubmoduleSidebarRow(submodule: submodule)
      .contextMenu {
        Button("Open Submodule") {
          store.openSubmodule(submodule)
        }
        Button("Update Submodule") {
          Task { await store.updateSubmodule(submodule) }
        }
        Button("Copy Path") {
          PasteboardWriter.copy(submodule.path)
        }
      }
    }
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

  private var repositoryHeaderDetail: String {
    let changeCount = store.snapshot.status.count
    let changeLabel = changeCount == 1 ? "change" : "changes"
    let state = changeCount == 0 ? "clean" : "\(changeCount.formatted()) \(changeLabel)"
    guard let branchName = store.currentBranch?.shortName else {
      return "No branch, \(state)"
    }
    return "\(branchName), \(state)"
  }
}

private struct RepositoryHeaderRow: View {
  var repository: GitRepository
  var detail: String
  var path: String

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "externaldrive")
        .foregroundStyle(.secondary)
        .frame(width: 16)

      VStack(alignment: .leading, spacing: 2) {
        Text(repository.name)
          .fontWeight(.semibold)
          .lineLimit(1)
        Text(detail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .help(path)
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

private struct ReferenceCopyMenu: View {
  var ref: GitRef

  var body: some View {
    Button("Copy Name") {
      PasteboardWriter.copy(ref.shortName)
    }
    Button("Copy Full Reference Name") {
      PasteboardWriter.copy(ref.name)
    }
    Button("Copy Commit Hash") {
      PasteboardWriter.copy(ref.objectName)
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

private struct SidebarDisclosureLabel: View {
  var title: String
  var count: Int
  var systemImage: String

  var body: some View {
    HStack {
      Label(title, systemImage: systemImage)
      Spacer()
      Text(count.formatted())
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }
  }
}

private struct WorktreeSidebarRow: View {
  var worktree: GitWorktree
  var isCurrent: Bool

  var body: some View {
    AdvancedSidebarRow(
      title: worktree.name,
      detail: worktree.displayState,
      tertiary: nil,
      systemImage: isCurrent ? "checkmark.circle.fill" : "square.stack.3d.up",
      iconStyle: isCurrent ? .green : .secondary
    )
    .help(worktree.path)
  }
}

private struct RemoteSidebarRow: View {
  var remote: GitRemote

  var body: some View {
    AdvancedSidebarRow(
      title: remote.name,
      detail: detail,
      tertiary: nil,
      systemImage: "network",
      iconStyle: .secondary
    )
    .help(helpText)
  }

  private var detail: String {
    switch (remote.fetchURL, remote.pushURL) {
    case (.some, .some):
      return "Fetch and push"
    case (.some, .none):
      return "Fetch only"
    case (.none, .some):
      return "Push only"
    case (.none, .none):
      return "No URL configured"
    }
  }

  private var helpText: String {
    let urls = [
      remote.fetchURL.map { "Fetch: \($0)" },
      remote.pushURL.map { "Push: \($0)" }
    ]
    .compactMap { $0 }
    return urls.isEmpty ? "No URL configured" : urls.joined(separator: "\n")
  }
}

private struct SubmoduleSidebarRow: View {
  var submodule: GitSubmodule

  var body: some View {
    AdvancedSidebarRow(
      title: submodule.path,
      detail: "\(submodule.statusTitle) - \(submodule.shortCommit)",
      tertiary: nil,
      systemImage: "shippingbox",
      iconStyle: submodule.status == "U" ? .orange : .secondary
    )
  }
}

private struct LFSFileSidebarRow: View {
  var file: GitLFSFile

  var body: some View {
    AdvancedSidebarRow(
      title: file.path,
      detail: file.shortOID,
      tertiary: nil,
      systemImage: "doc",
      iconStyle: .secondary
    )
    .help(file.oid)
  }
}

private struct AdvancedSidebarRow: View {
  var title: String
  var detail: String
  var tertiary: String?
  var systemImage: String
  var iconStyle: Color

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: systemImage)
        .foregroundStyle(iconStyle)
        .frame(width: 16)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .lineLimit(1)
        Text(detail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
        if let tertiary {
          Text(tertiary)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .lineLimit(1)
        }
      }
    }
  }
}

private struct SidebarInlineAction: View {
  var title: String
  var systemImage: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: systemImage)
        .foregroundStyle(.secondary)
        .frame(width: 16)
      Text(title)
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
