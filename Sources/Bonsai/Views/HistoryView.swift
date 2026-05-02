import SwiftUI

struct HistoryView: View {
  @Bindable var store: RepositoryStore
  @AppStorage("bonsai.showCommitRowDetails") private var showCommitRowDetails = false

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
        TextField("Search commits", text: $store.historySearchText)
          .textFieldStyle(.plain)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      Divider()

      List(selection: Binding(
        get: { store.selectedCommit?.id },
        set: { id in
          store.selectCommit(store.snapshot.commits.first(where: { $0.id == id }))
        }
      )) {
        if !store.snapshot.stashes.isEmpty {
          Section("Stashes") {
            ForEach(store.snapshot.stashes) { stash in
              StashRow(stash: stash, isSelected: store.selectedStash?.id == stash.id)
                .contentShape(Rectangle())
                .onTapGesture {
                  store.selectStash(stash)
                }
                .contextMenu {
                  Button("Apply") {
                    Task { await store.applyStash(stash, pop: false) }
                  }
                  Button("Pop") {
                    Task { await store.applyStash(stash, pop: true) }
                  }
                  Button("Drop", role: .destructive) {
                    store.presentDropStash(stash)
                  }
                }
            }
          }
        }

        ForEach(store.filteredCommits) { commit in
          CommitRow(commit: commit, showsDetails: showCommitRowDetails)
            .tag(commit.id)
            .contextMenu {
              Button("Cherry-pick") {
                store.selectCommit(commit)
                Task { await store.runRevisionCommand("cherry-pick") }
              }
              Button("Revert") {
                store.selectCommit(commit)
                Task { await store.runRevisionCommand("revert") }
              }
              Button("Merge") {
                store.selectCommit(commit)
                Task { await store.runRevisionCommand("merge") }
              }
              Button("Rebase Onto") {
                store.selectCommit(commit)
                Task { await store.runRevisionCommand("rebase") }
              }
              Button("Reset Here...") {
                store.selectCommit(commit)
                store.presentResetToSelectedCommit()
              }
              Button("Create Branch Here") {
                store.selectCommit(commit)
                store.presentCreateBranch()
              }
              Divider()
              Button("Copy Hash") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(commit.hash, forType: .string)
              }
            }
        }
      }
      .listStyle(.plain)

      Divider()

      ChangedFilesView(store: store)
        .frame(minHeight: 180, idealHeight: 220, maxHeight: 280)
    }
  }
}

private struct StashRow: View {
  var stash: GitStash
  var isSelected: Bool

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
    .padding(.horizontal, isSelected ? 6 : 0)
    .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
  }
}

private struct CommitRow: View {
  var commit: GitCommit
  var showsDetails: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: showsDetails ? 6 : 0) {
      HStack(spacing: 8) {
        Text(commit.graph.isEmpty ? "*" : commit.graph)
          .font(.caption.monospaced())
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .frame(width: 42, alignment: .leading)
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
            .frame(width: 42)
          Text(commit.authorName)
          if let date = commit.date {
            Text(date, style: .relative)
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

private struct ChangedFilesView: View {
  let store: RepositoryStore
  @State private var mode: CommitFilePanelMode = .changed

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Picker("Commit panel", selection: $mode) {
          ForEach(CommitFilePanelMode.allCases) { mode in
            Text(mode.title).tag(mode)
          }
        }
        .pickerStyle(.segmented)
        .controlSize(.small)
        .labelsHidden()
        .accessibilityLabel("Commit panel")
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
              Spacer()
            }
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
            }
          }
          .listStyle(.plain)
        }
      }
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
