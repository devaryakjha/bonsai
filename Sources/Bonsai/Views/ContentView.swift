import SwiftUI

struct ContentView: View {
  @Bindable var store: RepositoryStore
  @AppStorage("bonsai.showToolbarLabels") private var showToolbarLabels = false
  @FocusState private var navigationFocus: NavigationFocusTarget?

  var body: some View {
    NavigationSplitView {
      SidebarView(store: store, navigationFocus: $navigationFocus)
        .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
    } content: {
      MainContentView(store: store, navigationFocus: $navigationFocus)
        .navigationSplitViewColumnWidth(min: 420, ideal: 560)
    } detail: {
      DetailView(store: store)
        .navigationSplitViewColumnWidth(min: 360, ideal: 520)
    }
    .onKeyPress(.tab) {
      guard NavigationFocusTarget.canHandleTabShortcut else {
        return .ignored
      }
      navigationFocus = NavigationFocusTarget.tabDestination(from: navigationFocus)
      return .handled
    }
    .toolbar {
      ToolbarItemGroup {
        Button {
          store.presentOpenRepositoryPanel()
        } label: {
          ToolbarLabel("Open", systemImage: "folder", showTitle: showToolbarLabels)
        }

        Menu {
          Button("Clone Repository…") {
            store.presentCloneRepository()
          }
          Button("Create Repository…") {
            store.presentCreateRepository()
          }
        } label: {
          ToolbarLabel("New", systemImage: "plus", showTitle: showToolbarLabels)
        }

        Button {
          Task { await store.refreshAll() }
        } label: {
          ToolbarLabel("Refresh", systemImage: "arrow.clockwise", showTitle: showToolbarLabels)
        }
        .disabled(store.selectedRepository == nil || store.isRefreshing)
      }

      ToolbarItemGroup {
        Button {
          Task { await store.runRepositoryAction(.fetch) }
        } label: {
          ToolbarLabel("Fetch", systemImage: "arrow.down.circle", showTitle: showToolbarLabels)
        }
        .disabled(store.selectedRepository == nil)

        Button {
          Task { await store.runRepositoryAction(.pull) }
        } label: {
          ToolbarLabel(store.currentBranch?.pullTitle ?? "Pull", systemImage: "arrow.down.to.line.circle", showTitle: showToolbarLabels)
        }
        .disabled(store.selectedRepository == nil || !store.canPull)
        .help(store.pullReadinessIssue ?? "Pull")

        Button {
          Task { await store.runRepositoryAction(.push) }
        } label: {
          ToolbarLabel(store.pushActionTitle, systemImage: "arrow.up.to.line.circle", showTitle: showToolbarLabels)
        }
        .disabled(store.selectedRepository == nil || !store.canPush)
        .help(store.pushReadinessIssue ?? store.pushActionTitle)
      }

      ToolbarItemGroup {
        RepositoryToolbarActionsGroup(store: store, showToolbarLabels: showToolbarLabels)
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
    .sheet(item: $store.annotatedTagRequest) { request in
      AnnotatedTagSheet(
        request: request,
        name: $store.annotatedTagName,
        message: $store.annotatedTagMessage,
        onCancel: {
          store.annotatedTagRequest = nil
          store.annotatedTagName = ""
          store.annotatedTagMessage = ""
        },
        onCreate: {
          Task { await store.createRequestedAnnotatedTag() }
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
    .sheet(item: $store.repositoryBenchmarkReport) { report in
      RepositoryBenchmarkSheet(report: report) {
        store.repositoryBenchmarkReport = nil
      }
    }
    .sheet(item: $store.repositoryTreemapReport) { report in
      RepositoryTreemapSheet(report: report) {
        store.repositoryTreemapReport = nil
      }
    }
    .sheet(item: $store.codeAgentBranchReviewDocument) { document in
      CodeAgentBranchReviewSheet(
        document: document,
        onCopy: {
          store.copyCodeAgentBranchReview()
        },
        onClose: {
          store.codeAgentBranchReviewDocument = nil
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
    .sheet(item: $store.discardChangeRequest) { request in
      DiscardChangeSheet(
        request: request,
        onCancel: {
          store.discardChangeRequest = nil
        },
        onDiscard: {
          Task { await store.discardChange() }
        }
      )
    }
    .sheet(item: $store.discardUnstagedChangesRequest) { request in
      DiscardUnstagedChangesSheet(
        request: request,
        onCancel: {
          store.discardUnstagedChangesRequest = nil
        },
        onDiscard: {
          Task { await store.discardUnstagedChanges() }
        }
      )
    }
    .sheet(item: $store.cleanIgnoredFilesRequest) { request in
      CleanIgnoredFilesSheet(
        request: request,
        onCancel: {
          store.cleanIgnoredFilesRequest = nil
        },
        onClean: {
          Task { await store.cleanIgnoredFiles() }
        }
      )
    }
    .sheet(item: $store.removeFileFromHistoryRequest) { request in
      RemoveFileFromHistorySheet(
        request: request,
        path: $store.removeFileFromHistoryPath,
        onCancel: {
          store.removeFileFromHistoryRequest = nil
        },
        onRemove: {
          Task { await store.removeFileFromHistory() }
        }
      )
    }
    .sheet(item: $store.gitIgnoreTemplateRequest) { request in
      GitIgnoreTemplateSheet(
        request: request,
        selectedTemplateID: $store.selectedGitIgnoreTemplateID,
        onCancel: {
          store.gitIgnoreTemplateRequest = nil
        },
        onApply: {
          Task { await store.applySelectedGitIgnoreTemplate() }
        }
      )
    }
    .sheet(item: $store.discardPatchRequest) { request in
      DiscardPatchSheet(
        request: request,
        onCancel: {
          store.discardPatchRequest = nil
        },
        onDiscard: {
          Task { await store.discardPatch() }
        }
      )
    }
    .sheet(item: $store.applyPatchRequest) { request in
      ApplyPatchSheet(
        request: request,
        onCancel: {
          store.applyPatchRequest = nil
        },
        onApply: {
          Task { await store.applyRequestedPatch() }
        }
      )
    }
    .sheet(item: $store.dropStashRequest) { request in
      DropStashSheet(
        request: request,
        onCancel: {
          store.dropStashRequest = nil
        },
        onDrop: {
          Task { await store.dropRequestedStash() }
        }
      )
    }
    .sheet(item: $store.revisionCommandRequest) { request in
      RevisionCommandSheet(
        request: request,
        readiness: store.revisionCommandConflictReadiness,
        updateRefs: $store.revisionCommandUpdateRefs,
        onCancel: {
          store.revisionCommandRequest = nil
          store.revisionCommandConflictReadiness = nil
          store.revisionCommandUpdateRefs = false
        },
        onConfirm: {
          Task { await store.runRequestedRevisionCommand() }
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
    .sheet(item: $store.deleteRefRequest) { request in
      DeleteRefSheet(
        request: request,
        forceDelete: $store.deleteRefForce,
        onCancel: {
          store.deleteRefRequest = nil
          store.deleteRefForce = false
        },
        onDelete: {
          Task { await store.deleteRequestedRef() }
        }
      )
    }
    .sheet(item: $store.staleLocalBranchesRequest) { request in
      StaleLocalBranchesSheet(
        request: request,
        selectedBranchIDs: $store.staleBranchSelection,
        forceDelete: $store.staleBranchForceDelete,
        onCancel: {
          store.staleLocalBranchesRequest = nil
          store.staleBranchSelection = []
          store.staleBranchForceDelete = false
        },
        onDelete: {
          Task { await store.deleteSelectedStaleLocalBranches() }
        }
      )
    }
    .sheet(item: $store.forcePushRequest) { request in
      ForcePushSheet(
        request: request,
        onCancel: {
          store.forcePushRequest = nil
        },
        onConfirm: {
          Task { await store.forcePushRequestedBranch() }
        }
      )
    }
    .sheet(isPresented: Binding(
      get: { !store.reflogEntries.isEmpty },
      set: { if !$0 { store.reflogEntries = [] } }
    )) {
      ReflogSheet(
        entries: store.reflogEntries,
        onCancel: {
          store.reflogEntries = []
        },
        onCheckout: { entry in
          Task { await store.checkoutReflogEntry(entry) }
        },
        onReset: { entry in
          store.presentResetToReflogEntry(entry)
        }
      )
    }
    .sheet(item: $store.blameDocument) { document in
      BlameSheet(
        document: document,
        onCancel: {
          store.blameDocument = nil
        },
        onSelectCommit: { line in
          Task { await store.focusCommit(hash: line.commitHash) }
        }
      )
    }
    .sheet(item: $store.fileHistoryDocument) { document in
      FileHistorySheet(
        title: "File history",
        path: document.path,
        entries: document.entries,
        onCancel: {
          store.fileHistoryDocument = nil
        },
        onSelectCommit: { entry in
          Task { await store.focusCommit(hash: entry.hash) }
        }
      )
    }
    .sheet(item: $store.lineHistoryDocument) { document in
      FileHistorySheet(
        title: "Line history",
        path: "\(document.path), \(document.rangeTitle)",
        entries: document.entries,
        onCancel: {
          store.lineHistoryDocument = nil
        },
        onSelectCommit: { entry in
          Task { await store.focusCommit(hash: entry.hash) }
        }
      )
    }
    .sheet(item: $store.reflogResetRequest) { request in
      ReflogResetSheet(
        request: request,
        onCancel: {
          store.reflogResetRequest = nil
        },
        onConfirm: { mode in
          Task { await store.resetToReflogEntry(mode: mode) }
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
    .sheet(item: $store.removeRemoteRequest) { request in
      RemoveRemoteSheet(
        request: request,
        onCancel: {
          store.removeRemoteRequest = nil
        },
        onRemove: {
          Task { await store.removeRequestedRemote() }
        }
      )
    }
    .sheet(item: $store.remoteTagDeleteRequest) { request in
      DeleteRemoteTagSheet(
        request: request,
        onCancel: {
          store.remoteTagDeleteRequest = nil
        },
        onDelete: {
          Task { await store.deleteRequestedRemoteTag() }
        }
      )
    }
    .sheet(item: $store.removeWorktreeRequest) { request in
      RemoveWorktreeSheet(
        request: request,
        forceRemove: $store.removeWorktreeForce,
        onCancel: {
          store.removeWorktreeRequest = nil
          store.removeWorktreeForce = false
        },
        onRemove: {
          Task { await store.removeRequestedWorktree() }
        }
      )
    }
    .sheet(item: $store.createWorktreeRequest) { request in
      CreateWorktreeSheet(
        request: request,
        destinationPath: $store.createWorktreeDestinationPath,
        branchName: $store.createWorktreeBranchName,
        onCancel: {
          store.createWorktreeRequest = nil
          store.createWorktreeDestinationPath = ""
          store.createWorktreeBranchName = ""
        },
        onConfirm: {
          Task { await store.createRequestedWorktree() }
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
      await store.runPeriodicRefreshChecks()
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

private struct CodeAgentBranchReviewSheet: View {
  var document: CodeAgentBranchReviewDocument
  var onCopy: () -> Void
  var onClose: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 3) {
          Text("\(document.providerName) branch review")
            .font(.bonsaiSheetTitle)
            .lineLimit(1)
          Text("\(document.branchName) against \(document.baseReference)")
            .font(.bonsaiMonospacedMetadata)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .help("\(document.branchName) against \(document.baseReference)")
        }

        Spacer()

        Button {
          onCopy()
        } label: {
          Label("Copy review", systemImage: "doc.on.doc")
        }
        Button("Close", action: onClose)
      }

      ScrollView {
        Text(document.text)
          .font(.body.monospaced())
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(minWidth: 720, minHeight: 420)
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .stroke(.quaternary)
      }
    }
    .padding(20)
  }
}

private struct FileHistorySheet: View {
  var title: String
  var path: String
  var entries: [GitFileHistoryEntry]
  var onCancel: () -> Void
  var onSelectCommit: (GitFileHistoryEntry) -> Void

  @State private var searchText = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text(title)
            .font(.bonsaiSheetTitle)
          Text(path)
            .font(.bonsaiMonospacedMetadata)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer()
        InspectionSearchField(text: $searchText, accessibilityLabel: "Search file history")
        Button("Close", action: onCancel)
      }

      if filteredEntries.isEmpty {
        ContentUnavailableView(emptyTitle, systemImage: "magnifyingglass")
          .frame(minHeight: 420)
      } else {
        List(filteredEntries) { entry in
          FileHistoryRow(path: path, entry: entry, onSelectCommit: onSelectCommit)
        }
        .listStyle(.inset)
        .frame(minHeight: 420)
      }
    }
    .padding(20)
    .frame(minWidth: 840, minHeight: 540)
  }

  private var filteredEntries: [GitFileHistoryEntry] {
    InspectionFilter.fileHistory(entries, matching: searchText)
  }

  private var emptyTitle: String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No entries" : "No matches"
  }
}

private struct FileHistoryRow: View {
  var path: String
  var entry: GitFileHistoryEntry
  var onSelectCommit: (GitFileHistoryEntry) -> Void

  var body: some View {
    HStack(alignment: .top, spacing: InterfaceSpacing.panelHorizontal) {
      Button {
        onSelectCommit(entry)
      } label: {
        Image(systemName: "arrow.right.circle")
      }
      .bonsaiCompactIconButton()
      .help("Show commit")
      .accessibilityLabel("Show commit \(entry.shortHash)")

      Text(entry.shortHash)
        .font(.bonsaiMonospacedMetadata)
        .foregroundStyle(.secondary)
        .frame(width: 72, alignment: .leading)
        .textSelection(.enabled)

      VStack(alignment: .leading, spacing: InterfaceSpacing.small) {
        Text(entry.subject)
          .lineLimit(1)
          .textSelection(.enabled)

        HStack(spacing: InterfaceSpacing.medium) {
          Text(entry.authorName)
            .lineLimit(1)
            .help(entry.authorEmail)
          if let date = entry.date {
            Text(StaticDateText.date(date))
          }
        }
        .font(.bonsaiMetadata)
        .foregroundStyle(.secondary)

        if !entry.changes.isEmpty {
          ScrollView(.horizontal) {
            HStack(spacing: InterfaceSpacing.small) {
              ForEach(entry.changes) { change in
                FileChangePill(change: change)
              }
            }
          }
          .scrollIndicators(.hidden)
        }
      }
    }
    .padding(.vertical, InterfaceSpacing.small)
    .contextMenu {
      Button("Show Commit") {
        onSelectCommit(entry)
      }
      Button("Copy Commit Hash") {
        PasteboardWriter.copy(entry.hash)
      }
      Button("Copy Subject") {
        PasteboardWriter.copy(entry.subject)
      }
      if !entry.authorEmail.isEmpty {
        Button("Copy Author Email") {
          PasteboardWriter.copy(entry.authorEmail)
        }
      }
      if !entry.changedPathsForCopy.isEmpty {
        Button(entry.changedPathCopyCount == 1 ? "Copy Changed Path" : "Copy Changed Paths") {
          PasteboardWriter.copy(entry.changedPathsForCopy)
        }
      }
      if let previousPaths = entry.previousPathsForCopy {
        Button(entry.previousPathCopyCount == 1 ? "Copy Previous Path" : "Copy Previous Paths") {
          PasteboardWriter.copy(previousPaths)
        }
      }
      Button("Copy Inspected Path") {
        PasteboardWriter.copy(path)
      }
    }
  }
}

private struct FileChangePill: View {
  var change: GitChangedFile

  var body: some View {
    HStack(spacing: InterfaceSpacing.small) {
      ChangeStatusBadge(changedFile: change)
      Text(change.oldPath.map { "\($0) -> \(change.path)" } ?? change.path)
        .font(.bonsaiMonospacedMetadata)
        .lineLimit(1)
        .truncationMode(.middle)
    }
    .help(change.oldPath.map { "\($0) -> \(change.path)" } ?? change.path)
    .padding(.horizontal, InterfaceSpacing.medium)
    .padding(.vertical, 3)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
  }
}

private struct BlameSheet: View {
  var document: GitBlameDocument
  var onCancel: () -> Void
  var onSelectCommit: (GitBlameLine) -> Void

  @State private var searchText = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text("Blame")
            .font(.bonsaiSheetTitle)
          Text(document.path)
            .font(.bonsaiMonospacedMetadata)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer()
        InspectionSearchField(text: $searchText, accessibilityLabel: "Search blame")
        Button("Close", action: onCancel)
      }

      ScrollView([.horizontal, .vertical]) {
        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
          Section {
            if filteredLines.isEmpty {
              Text(emptyTitle)
                .font(.bonsaiMetadata)
                .foregroundStyle(.secondary)
                .frame(minWidth: 820, minHeight: 360)
            }
            ForEach(filteredLines) { line in
              BlameRow(path: document.path, line: line, onSelectCommit: onSelectCommit)
              Divider()
            }
          } header: {
            BlameHeaderRow()
              .background(.regularMaterial)
          }
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .stroke(.quaternary)
      }
    }
    .padding(20)
    .frame(minWidth: 900, minHeight: 560)
  }

  private var filteredLines: [GitBlameLine] {
    InspectionFilter.blameLines(document.lines, matching: searchText)
  }

  private var emptyTitle: String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No blame lines" : "No matches"
  }
}

private struct InspectionSearchField: View {
  @Binding var text: String
  var accessibilityLabel: String

  var body: some View {
    TextField("Search", text: $text)
      .textFieldStyle(.roundedBorder)
      .controlSize(.small)
      .frame(width: 220)
      .accessibilityLabel(accessibilityLabel)
  }
}

private struct BlameHeaderRow: View {
  var body: some View {
      HStack(spacing: InterfaceSpacing.panelHorizontal) {
        Color.clear
        .frame(width: InterfaceSize.compactIconButton)
        .accessibilityHidden(true)
      Text("Line")
        .frame(width: 52, alignment: .trailing)
      Text("Commit")
        .frame(width: 72, alignment: .leading)
      Text("Author")
        .frame(width: 160, alignment: .leading)
      Text("Date")
        .frame(width: 132, alignment: .leading)
      Text("Content")
        .frame(minWidth: 360, alignment: .leading)
    }
    .font(.bonsaiMetadata.weight(.semibold))
    .foregroundStyle(.secondary)
    .padding(.horizontal, InterfaceSpacing.large)
    .padding(.vertical, InterfaceSpacing.medium)
  }
}

private struct BlameRow: View {
  var path: String
  var line: GitBlameLine
  var onSelectCommit: (GitBlameLine) -> Void

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Button {
        onSelectCommit(line)
      } label: {
        Image(systemName: "arrow.right.circle")
      }
      .bonsaiCompactIconButton()
      .help("Show commit")
      .accessibilityLabel("Show commit \(line.shortHash)")

      Text("\(line.finalLine)")
        .foregroundStyle(.secondary)
        .frame(width: 52, alignment: .trailing)

      Text(line.shortHash)
        .foregroundStyle(.secondary)
        .frame(width: 72, alignment: .leading)
        .textSelection(.enabled)

      Text(line.author.isEmpty ? "Unknown" : line.author)
        .frame(width: 160, alignment: .leading)
        .lineLimit(1)
        .help(line.authorMail ?? line.author)

      Text(dateText)
        .foregroundStyle(.secondary)
        .frame(width: 132, alignment: .leading)

      Text(line.content.isEmpty ? " " : line.content)
        .frame(minWidth: 360, alignment: .leading)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .textSelection(.enabled)
    }
    .font(.bonsaiMonospacedMetadata)
    .padding(.horizontal, InterfaceSpacing.large)
    .padding(.vertical, InterfaceSpacing.small)
    .contextMenu {
      Button("Show Commit") {
        onSelectCommit(line)
      }
      Button("Copy Commit Hash") {
        PasteboardWriter.copy(line.commitHash)
      }
      Button("Copy Line Reference") {
        PasteboardWriter.copy(line.lineReference(path: path))
      }
      Button("Copy Line Content") {
        PasteboardWriter.copy(line.content)
      }
      if let authorMail = line.authorMail, !authorMail.isEmpty {
        Button("Copy Author Email") {
          PasteboardWriter.copy(authorMail)
        }
      }
    }
  }

  private var dateText: String {
    line.authorTime?.formatted(date: .abbreviated, time: .shortened) ?? "-"
  }
}

private struct DiscardChangeSheet: View {
  var request: DiscardChangeRequest
  var onCancel: () -> Void
  var onDiscard: () -> Void
  @State private var confirmed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Discard change")
        .font(.bonsaiSheetTitle)

      Text(request.entry.path)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.entry.isUntracked ? "This will remove the untracked file." : "This will restore the file from Git and discard local edits.")
        .foregroundStyle(.secondary)

      DestructiveConfirmationToggle(title: "Confirm discard", isOn: $confirmed)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Discard", role: .destructive, action: onDiscard)
          .buttonStyle(.borderedProminent)
          .disabled(!confirmed)
      }
    }
    .padding(20)
    .frame(width: 460)
  }
}

private struct DiscardUnstagedChangesSheet: View {
  var request: DiscardUnstagedChangesRequest
  var onCancel: () -> Void
  var onDiscard: () -> Void
  @State private var confirmed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Discard unstaged changes")
        .font(.bonsaiSheetTitle)

      Text("\(request.changeCount.formatted()) changes")
        .font(.body.monospaced())
        .lineLimit(1)

      Text(detail)
        .foregroundStyle(.secondary)

      DestructiveConfirmationToggle(title: "Confirm discard", isOn: $confirmed)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Discard", role: .destructive, action: onDiscard)
          .buttonStyle(.borderedProminent)
          .disabled(!confirmed)
      }
    }
    .padding(20)
    .frame(width: 460)
  }

  private var detail: String {
    let summary = request.summary.isEmpty ? "unstaged changes" : request.summary
    let action: String
    if request.trackedCount > 0 && request.untrackedCount > 0 {
      action = "This will restore tracked files from Git and remove untracked files."
    } else if request.trackedCount > 0 {
      action = "This will restore tracked files from Git."
    } else {
      action = "This will remove untracked files."
    }
    return "\(action) Includes: \(summary)."
  }
}

private struct CleanIgnoredFilesSheet: View {
  var request: CleanIgnoredFilesRequest
  var onCancel: () -> Void
  var onClean: () -> Void
  @State private var confirmed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Clean ignored files")
        .font(.bonsaiSheetTitle)

      Text(fileCountTitle)
        .font(.body.monospaced())
        .lineLimit(1)

      Text("This will remove ignored files and directories. Untracked files are not included.")
        .foregroundStyle(.secondary)

      DestructiveConfirmationToggle(title: "Confirm clean", isOn: $confirmed)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Clean", role: .destructive, action: onClean)
          .buttonStyle(.borderedProminent)
          .disabled(!confirmed)
      }
    }
    .padding(20)
    .frame(width: 460)
  }

  private var fileCountTitle: String {
    request.fileCount == 1 ? "1 ignored file" : "\(request.fileCount.formatted()) ignored files"
  }
}

private struct RemoveFileFromHistorySheet: View {
  var request: RemoveFileFromHistoryRequest
  @Binding var path: String
  var onCancel: () -> Void
  var onRemove: () -> Void
  @State private var confirmed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 6) {
        Text("Repository path")
          .font(.bonsaiMetadata)
          .foregroundStyle(.secondary)
        TextField("Path", text: $path)
          .textFieldStyle(.roundedBorder)
          .help("Repository-relative path")
      }

      Text("Bonsai requires a clean working tree. Remote branches and tags must be updated separately.")
        .foregroundStyle(.secondary)

      DestructiveConfirmationToggle(title: "Confirm history rewrite", isOn: $confirmed)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Remove", role: .destructive, action: onRemove)
          .buttonStyle(.borderedProminent)
          .disabled(!canRemove)
      }
    }
    .padding(20)
    .frame(width: 500)
  }

  private var canRemove: Bool {
    confirmed && !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}

private struct GitIgnoreTemplateSheet: View {
  var request: GitIgnoreTemplateRequest
  @Binding var selectedTemplateID: String
  var onCancel: () -> Void
  var onApply: () -> Void

  @State private var searchText = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text(request.title)
            .font(.bonsaiSheetTitle)
          Text(request.repositoryName)
            .font(.bonsaiMetadata)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer()
        InspectionSearchField(text: $searchText, accessibilityLabel: "Search gitignore templates")
      }

      if filteredTemplates.isEmpty {
        ContentUnavailableView(emptyTitle, systemImage: "magnifyingglass")
          .frame(minHeight: 300)
      } else {
        List(filteredTemplates, selection: selectionBinding) { template in
          VStack(alignment: .leading, spacing: 3) {
            Text(template.name)
              .lineLimit(1)
            Text(template.summary)
              .font(.bonsaiMetadata)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          .padding(.vertical, 4)
          .tag(template.id)
        }
        .listStyle(.inset)
        .frame(minHeight: 300)
      }

      HStack {
        Text(selectedTemplate?.summary ?? "Choose a template to apply.")
          .font(.bonsaiMetadata)
          .foregroundStyle(.secondary)
          .lineLimit(2)
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Apply", action: onApply)
          .buttonStyle(.borderedProminent)
          .disabled(selectedTemplate == nil)
      }
    }
    .padding(20)
    .frame(width: 520, height: 460)
  }

  private var filteredTemplates: [GitIgnoreTemplate] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return request.templates }
    return request.templates.filter { template in
      template.name.localizedCaseInsensitiveContains(query)
        || template.summary.localizedCaseInsensitiveContains(query)
    }
  }

  private var selectedTemplate: GitIgnoreTemplate? {
    request.templates.first { $0.id == selectedTemplateID }
  }

  private var emptyTitle: String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No templates" : "No matches"
  }

  private var selectionBinding: Binding<String?> {
    Binding<String?>(
      get: { selectedTemplateID },
      set: { newValue in
        if let newValue {
          selectedTemplateID = newValue
        }
      }
    )
  }
}

private struct DiscardPatchSheet: View {
  var request: DiscardPatchRequest
  var onCancel: () -> Void
  var onDiscard: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Discard", role: .destructive, action: onDiscard)
          .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 460)
  }
}

private struct ApplyPatchSheet: View {
  var request: ApplyPatchRequest
  var onCancel: () -> Void
  var onApply: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)

      Text(request.detail)
        .font(.bonsaiMetadata)
        .foregroundStyle(.secondary)

      ScrollView([.horizontal, .vertical]) {
        Text(request.previewText)
          .font(.bonsaiMonospacedMetadata)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(10)
      }
      .frame(minHeight: 180, maxHeight: 240)
      .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .stroke(.quaternary)
      }

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Apply", action: onApply)
          .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 560)
  }
}

private struct DropStashSheet: View {
  var request: DropStashRequest
  var onCancel: () -> Void
  var onDrop: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)
        .lineLimit(3)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Drop", role: .destructive, action: onDrop)
          .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 460)
  }
}

private struct RevisionCommandSheet: View {
  var request: RevisionCommandRequest
  var readiness: RevisionCommandConflictReadiness?
  @Binding var updateRefs: Bool
  var onCancel: () -> Void
  var onConfirm: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(1)

      Text(request.detail)
        .foregroundStyle(.secondary)
        .lineLimit(3)

      if let readiness {
        RevisionCommandReadinessRow(readiness: readiness)
      }

      if request.command == .rebase {
        Toggle("Update refs", isOn: $updateRefs)
          .help("Move branch refs that point into the rewritten range")
      }

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button(request.primaryActionTitle, action: onConfirm)
          .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 460)
  }
}

private struct RevisionCommandReadinessRow: View {
  var readiness: RevisionCommandConflictReadiness

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Image(systemName: readiness.systemImage)
        .foregroundStyle(statusColor)
        .bonsaiSidebarIconFrame()

      VStack(alignment: .leading, spacing: 2) {
        Text(readiness.title)
          .font(.callout)
          .fontWeight(.medium)
          .lineLimit(1)
        Text(readiness.detail)
          .font(.bonsaiMetadata)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
    }
    .padding(.vertical, InterfaceSpacing.panelVertical)
    .padding(.horizontal, InterfaceSpacing.large)
    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
  }

  private var statusColor: Color {
    switch readiness {
    case .checking, .unavailable:
      return .secondary
    case .clean:
      return .green
    case .conflicts:
      return .orange
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
  @State private var deleteConfirmation = ""

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
        .font(.bonsaiSheetTitle)

      if request.operation == .delete {
        Text("Deletion is permanent and requires a token with repository deletion permissions.")
          .foregroundStyle(.secondary)
      }

      if request.operation == .delete {
        VStack(alignment: .leading, spacing: 6) {
          Text("Owner")
            .font(.bonsaiMetadata)
            .foregroundStyle(.secondary)
          TextField("owner", text: $owner)
            .textFieldStyle(.roundedBorder)
        }
      }

      VStack(alignment: .leading, spacing: 6) {
        Text("Repository name")
          .font(.bonsaiMetadata)
          .foregroundStyle(.secondary)
        TextField("repository", text: $name)
          .textFieldStyle(.roundedBorder)
      }

      if request.operation == .create {
        VStack(alignment: .leading, spacing: 6) {
          Text("Description")
            .font(.bonsaiMetadata)
            .foregroundStyle(.secondary)
          TextField("Optional", text: $description)
            .textFieldStyle(.roundedBorder)
        }
        Toggle("Private", isOn: $isPrivate)
      }

      if request.operation == .delete {
        VStack(alignment: .leading, spacing: 6) {
          Text("Confirmation")
            .font(.bonsaiMetadata)
            .foregroundStyle(.secondary)
          Text(deleteTarget)
            .font(.bonsaiMonospacedMetadata)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 5))
            .help(deleteTarget)
            .accessibilityLabel("Repository to confirm: \(deleteTarget)")
          TextField(deleteTarget, text: $deleteConfirmation)
            .textFieldStyle(.roundedBorder)
            .help("Type \(deleteTarget) to confirm")
        }
      }

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button(role: request.operation == .delete ? .destructive : nil) {
          onConfirm(GitHubRepositoryRequest(
            operation: request.operation,
            owner: owner,
            name: name,
            repositoryDescription: description,
            isPrivate: isPrivate
          ))
        } label: {
          Text(request.operation.primaryActionTitle)
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
      return hasName
        && !owner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && deleteConfirmation.trimmingCharacters(in: .whitespacesAndNewlines) == deleteTarget
    }
    return hasName
  }

  private var deleteTarget: String {
    "\(owner.trimmingCharacters(in: .whitespacesAndNewlines))/\(name.trimmingCharacters(in: .whitespacesAndNewlines))"
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
        .font(.bonsaiSheetTitle)

      TextField("Name", text: $name)
        .textFieldStyle(.roundedBorder)

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

private struct RemoveRemoteSheet: View {
  var request: RemoveRemoteRequest
  var onCancel: () -> Void
  var onRemove: () -> Void
  @State private var confirmed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)
        .lineLimit(3)
        .textSelection(.enabled)

      DestructiveConfirmationToggle(title: "Confirm remove", isOn: $confirmed)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Remove", role: .destructive, action: onRemove)
          .buttonStyle(.borderedProminent)
          .disabled(!confirmed)
      }
    }
    .padding(20)
    .frame(width: 520)
  }
}

private struct DeleteRemoteTagSheet: View {
  var request: RemoteTagDeleteRequest
  var onCancel: () -> Void
  var onDelete: () -> Void
  @State private var confirmed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)

      DestructiveConfirmationToggle(title: "Confirm delete", isOn: $confirmed)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Delete", role: .destructive, action: onDelete)
          .buttonStyle(.borderedProminent)
          .disabled(!confirmed)
      }
    }
    .padding(20)
    .frame(width: 460)
  }
}

private struct RemoveWorktreeSheet: View {
  var request: RemoveWorktreeRequest
  @Binding var forceRemove: Bool
  var onCancel: () -> Void
  var onRemove: () -> Void
  @State private var confirmed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)
        .lineLimit(3)
        .textSelection(.enabled)

      Toggle("Force remove dirty worktree", isOn: $forceRemove)

      DestructiveConfirmationToggle(title: "Confirm remove", isOn: $confirmed)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Remove", role: .destructive, action: onRemove)
          .buttonStyle(.borderedProminent)
          .disabled(!confirmed)
      }
    }
    .padding(20)
    .frame(width: 520)
  }
}

private struct CreateWorktreeSheet: View {
  var request: CreateWorktreeRequest
  @Binding var destinationPath: String
  @Binding var branchName: String
  var onCancel: () -> Void
  var onConfirm: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 6) {
        Text("Destination")
          .font(.bonsaiMetadata)
          .foregroundStyle(.secondary)
        TextField("~/projects/repository-worktree", text: $destinationPath)
          .textFieldStyle(.roundedBorder)
      }

      VStack(alignment: .leading, spacing: 6) {
        Text("New branch")
          .font(.bonsaiMetadata)
          .foregroundStyle(.secondary)
        TextField("Optional branch name", text: $branchName)
          .textFieldStyle(.roundedBorder)
      }

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Create", action: onConfirm)
          .buttonStyle(.borderedProminent)
          .disabled(destinationPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .padding(20)
    .frame(width: 520)
    .onAppear {
      if destinationPath.isEmpty {
        destinationPath = request.defaultPath
      }
    }
  }
}

private struct ResetSheet: View {
  var request: ResetRequest
  var onCancel: () -> Void
  var onConfirm: (ResetMode) -> Void
  @State private var mode: ResetMode = .mixed
  @State private var confirmed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Reset branch")
        .font(.bonsaiSheetTitle)

      Text("Reset the current branch to \(request.commit.shortHash). Hard reset discards working tree changes.")
        .foregroundStyle(.secondary)

      Picker("Mode", selection: $mode) {
        ForEach(ResetMode.allCases) { mode in
          Text(mode.title).tag(mode)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .accessibilityLabel("Reset mode")

      Text(mode.detail)
        .font(.bonsaiMetadata)
        .foregroundStyle(mode == .hard ? .orange : .secondary)

      DestructiveConfirmationToggle(title: "Confirm reset", isOn: $confirmed)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Reset") {
          onConfirm(mode)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!confirmed)
      }
    }
    .padding(20)
    .frame(width: 460)
  }
}

private struct ReflogResetSheet: View {
  var request: ReflogResetRequest
  var onCancel: () -> Void
  var onConfirm: (ResetMode) -> Void
  @State private var mode: ResetMode = .mixed
  @State private var confirmed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Reset to reflog entry")
        .font(.bonsaiSheetTitle)

      Text("\(request.entry.selector) \(request.entry.shortHash)")
        .font(.body.monospaced())

      Text("Hard reset discards working tree changes.")
        .foregroundStyle(.secondary)

      Picker("Mode", selection: $mode) {
        ForEach(ResetMode.allCases) { mode in
          Text(mode.title).tag(mode)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .accessibilityLabel("Reset mode")

      Text(mode.detail)
        .font(.bonsaiMetadata)
        .foregroundStyle(mode == .hard ? .orange : .secondary)

      DestructiveConfirmationToggle(title: "Confirm reset", isOn: $confirmed)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Reset") {
          onConfirm(mode)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!confirmed)
      }
    }
    .padding(20)
    .frame(width: 480)
  }
}

private struct DeleteRefSheet: View {
  var request: DeleteRefRequest
  @Binding var forceDelete: Bool
  var onCancel: () -> Void
  var onDelete: () -> Void
  @State private var confirmed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)

      if request.allowsForceDelete {
        Toggle("Force delete unmerged branch", isOn: $forceDelete)
      }

      DestructiveConfirmationToggle(title: "Confirm delete", isOn: $confirmed)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Delete", role: .destructive, action: onDelete)
          .buttonStyle(.borderedProminent)
          .disabled(!confirmed)
      }
    }
    .padding(20)
    .frame(width: 460)
  }
}

private struct StaleLocalBranchesSheet: View {
  var request: StaleLocalBranchesRequest
  @Binding var selectedBranchIDs: Set<String>
  @Binding var forceDelete: Bool
  var onCancel: () -> Void
  var onDelete: () -> Void
  @State private var confirmed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 8) {
        ForEach(request.branches) { branch in
          Toggle(isOn: selectionBinding(for: branch)) {
            VStack(alignment: .leading, spacing: 2) {
              Text(branch.shortName)
                .fontWeight(.medium)
                .lineLimit(1)
              Text(branch.upstream ?? "Upstream gone")
                .font(.bonsaiMetadata)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
          }
          .toggleStyle(.checkbox)
        }
      }
      .padding(.vertical, 2)

      Toggle("Force delete unmerged branches", isOn: $forceDelete)

      Text(request.detail)
        .foregroundStyle(.secondary)

      DestructiveConfirmationToggle(title: "Confirm delete", isOn: $confirmed)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Delete Selected", role: .destructive, action: onDelete)
          .buttonStyle(.borderedProminent)
          .disabled(selectedBranchIDs.isEmpty || !confirmed)
      }
    }
    .padding(20)
    .frame(width: 500)
  }

  private func selectionBinding(for branch: GitRef) -> Binding<Bool> {
    Binding(
      get: {
        selectedBranchIDs.contains(branch.id)
      },
      set: { isSelected in
        if isSelected {
          selectedBranchIDs.insert(branch.id)
        } else {
          selectedBranchIDs.remove(branch.id)
        }
      }
    )
  }
}

private struct ForcePushSheet: View {
  var request: ForcePushRequest
  var onCancel: () -> Void
  var onConfirm: () -> Void
  @State private var confirmed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)

      DestructiveConfirmationToggle(title: "Confirm force push", isOn: $confirmed)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Force push", role: .destructive, action: onConfirm)
          .buttonStyle(.borderedProminent)
          .disabled(!confirmed)
      }
    }
    .padding(20)
    .frame(width: 480)
  }
}

private struct DestructiveConfirmationToggle: View {
  var title: String
  @Binding var isOn: Bool

  var body: some View {
    Toggle(title, isOn: $isOn)
      .toggleStyle(.checkbox)
      .font(.bonsaiMetadata)
  }
}

private struct ReflogSheet: View {
  var entries: [GitReflogEntry]
  var onCancel: () -> Void
  var onCheckout: (GitReflogEntry) -> Void
  var onReset: (GitReflogEntry) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Reflog")
          .font(.bonsaiSheetTitle)
        Spacer()
        Button("Close", action: onCancel)
      }

      Text("Recover a previous HEAD by checking it out or resetting the current branch.")
        .foregroundStyle(.secondary)

      List(entries) { entry in
        HStack(spacing: InterfaceSpacing.large) {
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text(entry.selector)
                .font(.bonsaiMonospacedMetadata)
                .foregroundStyle(.secondary)
              Text(entry.shortHash)
                .font(.bonsaiMonospacedMetadata)
                .foregroundStyle(.secondary)
            }
            Text(entry.subject)
              .lineLimit(1)
            if let date = entry.date {
              Text(StaticDateText.date(date))
                .font(.bonsaiMetadata)
                .foregroundStyle(.secondary)
            }
          }

          Spacer()

          Button("Checkout") {
            onCheckout(entry)
          }
          .buttonStyle(.borderless)
          .controlSize(.small)

          Button("Reset…") {
            onReset(entry)
          }
          .buttonStyle(.borderless)
          .controlSize(.small)
        }
        .padding(.vertical, InterfaceSpacing.xSmall)
      }
      .frame(minHeight: 360)
    }
    .padding(20)
    .frame(minWidth: 720, minHeight: 480)
  }
}

private struct InteractiveRebaseSheet: View {
  let store: RepositoryStore
  var onCancel: () -> Void
  var onStart: () -> Void
  @State private var showsTodoText = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Interactive rebase")
        .font(.bonsaiSheetTitle)

      if let plan = store.interactiveRebasePlan {
        HStack(spacing: 8) {
          Text("\(plan.items.count.formatted()) commits")
          Text(plan.upstream)
            .monospaced()
        }
        .font(.bonsaiMetadata)
        .foregroundStyle(.secondary)

        Toggle("Update refs", isOn: Binding(
          get: { store.interactiveRebasePlan?.updateRefs ?? false },
          set: { store.setInteractiveRebaseUpdateRefs($0) }
        ))
        .help("Move branch refs that point into the rewritten range")

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

        DisclosureGroup("Todo file", isExpanded: $showsTodoText) {
          Text(plan.todoText)
            .font(.bonsaiMonospacedMetadata)
            .foregroundStyle(.secondary)
            .lineLimit(8)
            .textSelection(.enabled)
            .padding(.top, 4)
        }
        .font(.bonsaiMetadata)

        if let validationMessage = plan.validationMessage {
          Label(validationMessage, systemImage: "exclamationmark.triangle")
            .font(.bonsaiMetadata)
            .foregroundStyle(.orange)
        }
      }

      HStack {
        Button("Cancel", action: onCancel)
        Spacer()
        Button("Start rebase", action: onStart)
          .buttonStyle(.borderedProminent)
          .disabled(store.interactiveRebasePlan?.canStart != true)
          .help(store.interactiveRebasePlan?.validationMessage ?? "Start rebase")
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
    HStack(spacing: InterfaceSpacing.large) {
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
        .font(.bonsaiMonospacedMetadata)
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
      .bonsaiCompactIconButton()
      .help("Move up")
      .accessibilityLabel("Move \(item.shortHash) up")

      Button {
        onMoveDown()
      } label: {
        Image(systemName: "chevron.down")
      }
      .disabled(!canMoveDown)
      .bonsaiCompactIconButton()
      .help("Move down")
      .accessibilityLabel("Move \(item.shortHash) down")
    }
    .padding(.horizontal, InterfaceSpacing.large)
    .padding(.vertical, InterfaceSpacing.panelVertical)
  }
}

private struct ConflictResolutionSheet: View {
  var request: ConflictResolutionRequest
  var onCancel: () -> Void
  var onResolve: (ConflictResolutionChoice) -> Void
  @State private var selectedSide: ConflictPreviewSide = .workingTree

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Resolve conflict")
        .font(.bonsaiSheetTitle)

      Text(request.entry.path)
        .foregroundStyle(.secondary)
        .lineLimit(1)

      Picker("Conflict side", selection: $selectedSide) {
        ForEach(request.previews) { preview in
          Text(preview.title).tag(preview.side)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .frame(width: 420)
      .accessibilityLabel("Conflict side")

      RichDiffTextView(text: selectedPreviewText)
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

  private var selectedPreviewText: String {
    request.previews.first(where: { $0.side == selectedSide })?.text
      ?? request.preview
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
      HStack(spacing: InterfaceSpacing.large) {
        BonsaiLogoMark()
          .frame(width: InterfaceSize.compactIconButton, height: InterfaceSize.compactIconButton)
          .accessibilityHidden(true)

        Text(mode.title)
          .font(.bonsaiSheetTitle)
          .lineLimit(1)
      }

      if mode == .clone {
        VStack(alignment: .leading, spacing: 6) {
          Text("Remote URL")
            .font(.bonsaiMetadata)
            .foregroundStyle(.secondary)
          TextField("git@github.com:owner/repository.git", text: $remoteURL)
            .textFieldStyle(.roundedBorder)
            .onSubmit(onRemoteChanged)
            .onChange(of: remoteURL) { _, _ in onRemoteChanged() }
        }
      }

      VStack(alignment: .leading, spacing: 6) {
        Text(mode == .clone ? "Destination" : "Repository folder")
          .font(.bonsaiMetadata)
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
          .accessibilityLabel("Choose folder")
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
        .font(.bonsaiSheetTitle)

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
          .disabled(!request.kind.allowsEmptyInput && input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .padding(20)
    .frame(width: 420)
  }
}

private struct AnnotatedTagSheet: View {
  var request: AnnotatedTagRequest
  @Binding var name: String
  @Binding var message: String
  var onCancel: () -> Void
  var onCreate: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.bonsaiSheetTitle)

      Text(request.message)
        .foregroundStyle(.secondary)

      TextField("v0.1.0", text: $name)
        .textFieldStyle(.roundedBorder)

      TextEditor(text: $message)
        .font(.body)
        .frame(height: 92)
        .overlay {
          RoundedRectangle(cornerRadius: 6)
            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        }

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Create", action: onCreate)
          .buttonStyle(.borderedProminent)
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .padding(20)
    .frame(width: 460)
  }
}
