import SwiftUI

@MainActor
struct HistoryView: View {
  @Bindable var store: RepositoryStore
  let navigationFocus: FocusState<NavigationFocusTarget?>.Binding
  @AppStorage("bonsai.showCommitRowDetails") private var showCommitRowDetails = false

  var body: some View {
    let graphColumnWidth = CGFloat(HistoryGraphColumn.pointWidth(for: store.filteredCommits))

    VStack(spacing: 0) {
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
        TextField("Search commits", text: $store.historySearchText)
          .textFieldStyle(.plain)
        Menu {
          Toggle("Show commit details", isOn: $showCommitRowDetails)
        } label: {
          Label("History options", systemImage: "slider.horizontal.3")
            .labelStyle(.iconOnly)
        }
        .menuStyle(.borderlessButton)
        .help("History options")
        .accessibilityLabel("History options")
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      Divider()

      List(selection: historySelection) {
        if !store.snapshot.stashes.isEmpty {
          Section("Stashes") {
            ForEach(store.snapshot.stashes) { stash in
              StashRow(stash: stash)
                .tag(HistorySelectionKey.stash(stash.id))
                .contextMenu {
                  Button("Apply") {
                    Task { await store.applyStash(stash, pop: false) }
                  }
                  Button("Pop") {
                    Task { await store.applyStash(stash, pop: true) }
                  }
                  Button("Create Branch…") {
                    store.presentStashBranch(stash)
                  }
                  Divider()
                  StashCopyMenu(stash: stash)
                  Button("Copy Patch") {
                    Task { await store.copyStashPatch(stash) }
                  }
                  Divider()
                  Button("Drop", role: .destructive) {
                    store.presentDropStash(stash)
                  }
                }
            }
          }
        }

        ForEach(store.filteredCommits) { commit in
          CommitRow(
            commit: commit,
            showsDetails: showCommitRowDetails,
            graphColumnWidth: graphColumnWidth
          )
            .tag(HistorySelectionKey.commit(commit.id))
            .contextMenu {
              Menu(CommitContextMenuCopy.revisionMenuTitle) {
                Button("Checkout") {
                  store.selectCommit(commit)
                  Task { await store.checkoutSelectedCommit() }
                }
                Button(GitRevisionCommand.cherryPick.historyTitle) {
                  store.selectCommit(commit)
                  store.presentRevisionCommand(.cherryPick)
                }
                Button(GitRevisionCommand.revert.historyTitle) {
                  store.selectCommit(commit)
                  store.presentRevisionCommand(.revert)
                }
                Button(GitRevisionCommand.merge.historyTitle) {
                  store.selectCommit(commit)
                  store.presentRevisionCommand(.merge)
                }
                Button(GitRevisionCommand.rebase.historyTitle) {
                  store.selectCommit(commit)
                  store.presentRevisionCommand(.rebase)
                }
                Divider()
                Button("Reset Here…") {
                  store.selectCommit(commit)
                  store.presentResetToSelectedCommit()
                }
              }
              Menu(CommitContextMenuCopy.createMenuTitle) {
                Button("Create Branch Here…") {
                  store.selectCommit(commit)
                  store.presentCreateBranch()
                }
                Button("Create Tag Here…") {
                  store.selectCommit(commit)
                  store.presentCreateTag()
                }
                Button("Create Annotated Tag Here…") {
                  store.selectCommit(commit)
                  store.presentCreateAnnotatedTag()
                }
              }
              if let webURL = store.webURL(forCommit: commit) {
                Menu(CommitContextMenuCopy.hostingMenuTitle) {
                  Button("Open in Browser") {
                    store.openCommitInBrowser(commit)
                  }
                  Button("Copy Web URL") {
                    PasteboardWriter.copy(webURL.absoluteString)
                  }
                }
              }
              Menu(CommitContextMenuCopy.copyMenuTitle) {
                CommitCopyCommands(commit: commit)
                Divider()
                Button("Copy Patch") {
                  Task { await store.copyCommitPatch(commit) }
                }
              }
            }
        }
      }
      .listStyle(.plain)
      .focusable()
      .focused(navigationFocus, equals: .history)

      Divider()

      ChangedFilesView(store: store)
        .frame(minHeight: 180, idealHeight: 220, maxHeight: 280)
    }
  }

  private var historySelection: Binding<String?> {
    Binding(
      get: {
        if let stash = store.selectedStash {
          return HistorySelectionKey.stash(stash.id)
        }
        return store.selectedCommit.map { HistorySelectionKey.commit($0.id) }
      },
      set: { id in
        guard let id else {
          store.selectCommit(nil)
          return
        }

        if let stashID = HistorySelectionKey.stashID(from: id) {
          store.selectStash(store.snapshot.stashes.first { $0.id == stashID })
        } else if let commitID = HistorySelectionKey.commitID(from: id) {
          store.selectCommit(store.snapshot.commits.first { $0.id == commitID })
        }
      }
    )
  }
}

private enum HistorySelectionKey {
  static func commit(_ id: String) -> String { "commit:\(id)" }
  static func stash(_ id: String) -> String { "stash:\(id)" }

  static func commitID(from key: String) -> String? {
    id(from: key, prefix: "commit:")
  }

  static func stashID(from key: String) -> String? {
    id(from: key, prefix: "stash:")
  }

  private static func id(from key: String, prefix: String) -> String? {
    guard key.hasPrefix(prefix) else { return nil }
    return String(key.dropFirst(prefix.count))
  }
}

private struct CommitCopyCommands: View {
  var commit: GitCommit

  var body: some View {
    Button("Copy Full Hash") {
      PasteboardWriter.copy(commit.hash)
    }
    Button("Copy Short Hash") {
      PasteboardWriter.copy(commit.shortHash)
    }
    Button("Copy Subject") {
      PasteboardWriter.copy(commit.subject)
    }
    Button("Copy Author Name") {
      PasteboardWriter.copy(commit.authorName)
    }
    if !commit.authorEmail.isEmpty {
      Button("Copy Author Email") {
        PasteboardWriter.copy(commit.authorEmail)
      }
    }
  }
}

private struct StashRow: View {
  var stash: GitStash

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        Label(stash.index, systemImage: "tray.full")
          .fontWeight(.medium)
        Spacer()
        Text("Stash")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text(stash.message)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .padding(.vertical, 4)
  }
}

private struct CommitRow: View {
  var commit: GitCommit
  var showsDetails: Bool
  var graphColumnWidth: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: showsDetails ? 6 : 0) {
      HStack(spacing: 8) {
        Text(commit.graph.isEmpty ? "*" : commit.graph)
          .font(.caption.monospaced())
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .frame(width: graphColumnWidth, alignment: .leading)
        Text(commit.subject)
          .lineLimit(1)
          .fontWeight(.medium)
        Spacer()
        Text(commit.shortHash)
          .font(.caption)
          .foregroundStyle(.secondary)
          .monospaced()
      }

      if showsDetails {
        HStack(spacing: 8) {
          Spacer()
            .frame(width: graphColumnWidth)
          Text(commit.authorName)
          if let date = commit.date {
            Text(StaticDateText.relativeOrDate(date))
          }
          ForEach(commit.decorations.prefix(3), id: \.self) { decoration in
            Text(decoration)
              .font(.caption2)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(.quaternary, in: Capsule())
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, showsDetails ? 4 : 3)
    .help(helpText)
  }

  private var helpText: String {
    var parts = [commit.shortHash, commit.authorName]
    if let date = commit.date {
      parts.append(date.formatted(date: .abbreviated, time: .shortened))
    }
    parts.append(contentsOf: commit.decorations)
    return parts.filter { !$0.isEmpty }.joined(separator: " - ")
  }
}

@MainActor
private struct ChangedFilesView: View {
  let store: RepositoryStore
  @State private var mode: CommitFilePanelMode = .changed

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        AppKitSegmentedControl(
          options: CommitFilePanelMode.allCases,
          selection: $mode,
          label: "Commit panel",
          controlSize: .small,
          title: \.title
        )
        .frame(width: 190)
        Spacer()
        Text(countText)
          .foregroundStyle(.secondary)
          .monospacedDigit()
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      switch mode {
      case .changed:
        List(selection: Binding(
          get: { store.selectedChangedFile?.id },
          set: { id in
            store.selectChangedFile(store.displayedChangedFiles.first(where: { $0.id == id }))
          }
        )) {
          ForEach(store.displayedChangedFiles) { file in
            HStack(spacing: 8) {
              ChangeStatusBadge(changedFile: file)
              Text(file.path)
                .lineLimit(1)
                .truncationMode(.middle)
              Spacer()
            }
            .help(file.oldPath.map { "\($0) -> \(file.path)" } ?? file.path)
            .tag(file.id)
            .contextMenu {
              Button("Blame") {
                store.selectChangedFile(file)
                Task { await store.showBlameForSelection() }
              }
              Button("File History") {
                store.selectChangedFile(file)
                Task { await store.showFileHistoryForSelection() }
              }
              Divider()
              Button("Copy Path") {
                PasteboardWriter.copy(file.path)
              }
              Button("Copy Absolute Path") {
                store.copyAbsoluteFilePath(path: file.path)
              }
              Button("Open") {
                store.openFile(path: file.path)
              }
              Menu("Open In") {
                ForEach(ExternalEditor.allCases) { editor in
                  Button(editor.title) {
                    store.openFile(path: file.path, in: editor)
                  }
                }
              }
              Button("Reveal in Finder") {
                store.revealInFinder(path: file.path)
              }
              if let oldPath = file.oldPath {
                Button("Copy Previous Path") {
                  PasteboardWriter.copy(oldPath)
                }
              }
            }
          }
        }
        .listStyle(.plain)
      case .tree:
        VStack(spacing: 0) {
          HStack(spacing: 8) {
            Button {
              store.navigateTreeUp()
            } label: {
              Label("Up", systemImage: "chevron.up")
            }
            .buttonStyle(.borderless)
            .disabled(store.commitTreePath.isEmpty)

            Text(store.commitTreePath.isEmpty ? "/" : store.commitTreePath)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .truncationMode(.middle)
              .help(store.commitTreePath.isEmpty ? "/" : store.commitTreePath)
            Spacer()
          }
          .padding(.horizontal, 12)
          .padding(.bottom, 6)

          List(selection: Binding(
            get: { store.selectedTreeEntry?.id },
            set: { id in
              guard let entry = store.commitTreeEntries.first(where: { $0.id == id }) else { return }
              store.openTreeEntry(entry)
            }
          )) {
            ForEach(store.commitTreeEntries) { entry in
              HStack(spacing: 8) {
                Image(systemName: entry.isDirectory ? "folder" : "doc.text")
                  .foregroundStyle(entry.isDirectory ? .blue : .secondary)
                  .frame(width: 16)
                Text(entry.name)
                  .lineLimit(1)
                Spacer()
              }
              .tag(entry.id)
              .onTapGesture {
                store.openTreeEntry(entry)
              }
              .contextMenu {
                Button("Copy Path") {
                  PasteboardWriter.copy(entry.path)
                }
                Button("Copy Absolute Path") {
                  store.copyAbsoluteFilePath(path: entry.path)
                }
                if store.workingTreePathExists(entry.path) {
                  Divider()
                  Button("Open") {
                    store.openFile(path: entry.path)
                  }
                  Menu("Open In") {
                    ForEach(ExternalEditor.allCases) { editor in
                      Button(editor.title) {
                        store.openFile(path: entry.path, in: editor)
                      }
                    }
                  }
                  Button("Reveal in Finder") {
                    store.revealInFinder(path: entry.path)
                  }
                }
              }
            }
          }
          .listStyle(.plain)
        }
      }
    }
    .onAppear {
      loadTreeIfNeeded(for: mode)
    }
    .onChange(of: mode) { _, newMode in
      loadTreeIfNeeded(for: newMode)
    }
  }

  private func loadTreeIfNeeded(for mode: CommitFilePanelMode) {
    guard mode == .tree else { return }
    Task {
      await store.ensureCommitTreeLoaded()
    }
  }

  private var countText: String {
    switch mode {
    case .changed:
      return store.displayedChangedFiles.count.formatted()
    case .tree:
      return store.commitTreeEntries.count.formatted()
    }
  }
}

private enum CommitFilePanelMode: String, CaseIterable, Identifiable {
  case changed
  case tree

  var id: String { rawValue }
  var title: String { self == .changed ? "Changed" : "Tree" }
}
