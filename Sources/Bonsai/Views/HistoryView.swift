import SwiftUI

struct HistoryView: View {
  @Bindable var store: RepositoryStore

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
        ForEach(store.filteredCommits) { commit in
          CommitRow(commit: commit)
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

private struct CommitRow: View {
  var commit: GitCommit

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        Text(commit.subject)
          .lineLimit(1)
          .fontWeight(.medium)
        Spacer()
        Text(commit.shortHash)
          .font(.caption)
          .foregroundStyle(.secondary)
          .monospaced()
      }

      HStack(spacing: 8) {
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
    .padding(.vertical, 4)
  }
}

private struct ChangedFilesView: View {
  let store: RepositoryStore
  @State private var mode: CommitFilePanelMode = .changed

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Picker("Commit Panel", selection: $mode) {
          ForEach(CommitFilePanelMode.allCases) { mode in
            Text(mode.title).tag(mode)
          }
        }
        .pickerStyle(.segmented)
        .controlSize(.small)
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
            store.selectChangedFile(store.snapshot.changedFiles.first(where: { $0.id == id }))
          }
        )) {
          ForEach(store.snapshot.changedFiles) { file in
            HStack {
              Text(file.status)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)
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
      return store.snapshot.changedFiles.count.formatted()
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
