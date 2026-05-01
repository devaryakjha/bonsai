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

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("Changed Files")
          .font(.headline)
        Spacer()
        Text(store.snapshot.changedFiles.count.formatted())
          .foregroundStyle(.secondary)
          .monospacedDigit()
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

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
    }
  }
}
