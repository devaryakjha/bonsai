import SwiftUI

struct ContentView: View {
  @Bindable var store: RepositoryStore
  @AppStorage("bonsai.showToolbarLabels") private var showToolbarLabels = false

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
        RepositoryToolbarActionsMenu(store: store, showToolbarLabels: showToolbarLabels)
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
        onCancel: {
          store.revisionCommandRequest = nil
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
            .font(.title3)
            .fontWeight(.semibold)
          Text(path)
            .font(.caption.monospaced())
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
    HStack(alignment: .top, spacing: 12) {
      Button {
        onSelectCommit(entry)
      } label: {
        Image(systemName: "arrow.right.circle")
      }
      .buttonStyle(.borderless)
      .help("Show commit")
      .accessibilityLabel("Show commit \(entry.shortHash)")

      Text(entry.shortHash)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .frame(width: 72, alignment: .leading)
        .textSelection(.enabled)

      VStack(alignment: .leading, spacing: 6) {
        Text(entry.subject)
          .lineLimit(1)
          .textSelection(.enabled)

        HStack(spacing: 8) {
          Text(entry.authorName)
            .lineLimit(1)
            .help(entry.authorEmail)
          if let date = entry.date {
            Text(date, style: .date)
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        if !entry.changes.isEmpty {
          ScrollView(.horizontal) {
            HStack(spacing: 6) {
              ForEach(entry.changes) { change in
                FileChangePill(change: change)
              }
            }
          }
          .scrollIndicators(.hidden)
        }
      }
    }
    .padding(.vertical, 5)
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
    HStack(spacing: 5) {
      ChangeStatusBadge(changedFile: change)
      Text(change.oldPath.map { "\($0) -> \(change.path)" } ?? change.path)
        .font(.caption.monospaced())
        .lineLimit(1)
        .truncationMode(.middle)
    }
    .help(change.oldPath.map { "\($0) -> \(change.path)" } ?? change.path)
    .padding(.horizontal, 7)
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
            .font(.title3)
            .fontWeight(.semibold)
          Text(document.path)
            .font(.caption.monospaced())
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
                .font(.caption)
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
    HStack(spacing: 12) {
      Color.clear
        .frame(width: 22)
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
    .font(.caption.weight(.semibold))
    .foregroundStyle(.secondary)
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
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
      .buttonStyle(.borderless)
      .help("Show commit")
      .accessibilityLabel("Show commit \(line.shortHash)")
      .frame(width: 22)

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
    .font(.caption.monospaced())
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
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

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Discard change")
        .font(.title3)
        .fontWeight(.semibold)

      Text(request.entry.path)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.entry.isUntracked ? "This will remove the untracked file." : "This will restore the file from Git and discard local edits.")
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
            .font(.title3)
            .fontWeight(.semibold)
          Text(request.repositoryName)
            .font(.caption)
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
              .font(.caption)
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
          .font(.caption)
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
        .font(.title3)
        .fontWeight(.semibold)

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

private struct DropStashSheet: View {
  var request: DropStashRequest
  var onCancel: () -> Void
  var onDrop: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.title3)
        .fontWeight(.semibold)

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
  var onCancel: () -> Void
  var onConfirm: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.title3)
        .fontWeight(.semibold)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(1)

      Text(request.detail)
        .foregroundStyle(.secondary)
        .lineLimit(3)

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
        .font(.title3)
        .fontWeight(.semibold)

      if request.operation == .delete {
        Text("Deletion is permanent and requires a token with repository deletion permissions.")
          .foregroundStyle(.secondary)
      }

      if request.operation == .delete {
        VStack(alignment: .leading, spacing: 6) {
          Text("Owner")
            .font(.caption)
            .foregroundStyle(.secondary)
          TextField("owner", text: $owner)
            .textFieldStyle(.roundedBorder)
        }
      }

      VStack(alignment: .leading, spacing: 6) {
        Text("Repository name")
          .font(.caption)
          .foregroundStyle(.secondary)
        TextField("repository", text: $name)
          .textFieldStyle(.roundedBorder)
      }

      if request.operation == .create {
        VStack(alignment: .leading, spacing: 6) {
          Text("Description")
            .font(.caption)
            .foregroundStyle(.secondary)
          TextField("Optional", text: $description)
            .textFieldStyle(.roundedBorder)
        }
        Toggle("Private", isOn: $isPrivate)
      }

      if request.operation == .delete {
        VStack(alignment: .leading, spacing: 6) {
          Text("Confirmation")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(deleteTarget)
            .font(.caption.monospaced())
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
        .font(.title3)
        .fontWeight(.semibold)

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

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.title3)
        .fontWeight(.semibold)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)
        .lineLimit(3)
        .textSelection(.enabled)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Remove", role: .destructive, action: onRemove)
          .buttonStyle(.borderedProminent)
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

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.title3)
        .fontWeight(.semibold)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Delete", role: .destructive, action: onDelete)
          .buttonStyle(.borderedProminent)
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

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.title3)
        .fontWeight(.semibold)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)
        .lineLimit(3)
        .textSelection(.enabled)

      Toggle("Force remove dirty worktree", isOn: $forceRemove)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Remove", role: .destructive, action: onRemove)
          .buttonStyle(.borderedProminent)
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
        .font(.title3)
        .fontWeight(.semibold)

      Text(request.message)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 6) {
        Text("Destination")
          .font(.caption)
          .foregroundStyle(.secondary)
        TextField("~/projects/repository-worktree", text: $destinationPath)
          .textFieldStyle(.roundedBorder)
      }

      VStack(alignment: .leading, spacing: 6) {
        Text("New branch")
          .font(.caption)
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

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Reset branch")
        .font(.title3)
        .fontWeight(.semibold)

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

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Reset") {
          onConfirm(mode)
        }
        .buttonStyle(.borderedProminent)
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

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Reset to reflog entry")
        .font(.title3)
        .fontWeight(.semibold)

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

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Reset") {
          onConfirm(mode)
        }
        .buttonStyle(.borderedProminent)
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

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.title3)
        .fontWeight(.semibold)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)

      if request.allowsForceDelete {
        Toggle("Force delete unmerged branch", isOn: $forceDelete)
      }

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Delete", role: .destructive, action: onDelete)
          .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 460)
  }
}

private struct ForcePushSheet: View {
  var request: ForcePushRequest
  var onCancel: () -> Void
  var onConfirm: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(request.title)
        .font(.title3)
        .fontWeight(.semibold)

      Text(request.message)
        .font(.body.monospaced())
        .lineLimit(2)

      Text(request.detail)
        .foregroundStyle(.secondary)

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
        Button("Force push", role: .destructive, action: onConfirm)
          .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 480)
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
          .font(.title3)
          .fontWeight(.semibold)
        Spacer()
        Button("Close", action: onCancel)
      }

      Text("Recover a previous HEAD by checking it out or resetting the current branch.")
        .foregroundStyle(.secondary)

      List(entries) { entry in
        HStack(spacing: 10) {
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text(entry.selector)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
              Text(entry.shortHash)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            }
            Text(entry.subject)
              .lineLimit(1)
            if let date = entry.date {
              Text(date, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }

          Spacer()

          Button("Checkout") {
            onCheckout(entry)
          }
          .buttonStyle(.borderless)

          Button("Reset…") {
            onReset(entry)
          }
          .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
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
        .font(.title3)
        .fontWeight(.semibold)

      if let plan = store.interactiveRebasePlan {
        HStack(spacing: 8) {
          Text("\(plan.items.count.formatted()) commits")
          Text(plan.upstream)
            .monospaced()
        }
        .font(.caption)
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
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(8)
            .textSelection(.enabled)
            .padding(.top, 4)
        }
        .font(.caption)

        if let validationMessage = plan.validationMessage {
          Label(validationMessage, systemImage: "exclamationmark.triangle")
            .font(.caption)
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
    HStack(spacing: 10) {
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
        .font(.caption.monospaced())
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
      .buttonStyle(.borderless)
      .help("Move up")
      .accessibilityLabel("Move \(item.shortHash) up")

      Button {
        onMoveDown()
      } label: {
        Image(systemName: "chevron.down")
      }
      .disabled(!canMoveDown)
      .buttonStyle(.borderless)
      .help("Move down")
      .accessibilityLabel("Move \(item.shortHash) down")
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
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
        .font(.title3)
        .fontWeight(.semibold)

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
      HStack(spacing: 10) {
        BonsaiLogoMark()
          .frame(width: 24, height: 24)
          .accessibilityHidden(true)

        Text(mode.title)
          .font(.title3)
          .fontWeight(.semibold)
          .lineLimit(1)
      }

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
        Text(mode == .clone ? "Destination" : "Repository folder")
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
        .font(.title3)
        .fontWeight(.semibold)

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
