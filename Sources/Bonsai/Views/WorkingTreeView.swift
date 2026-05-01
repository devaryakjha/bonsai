import SwiftUI

struct WorkingTreeView: View {
  @Bindable var store: RepositoryStore

  var body: some View {
    VStack(spacing: 0) {
      List {
        if !store.conflictedChanges.isEmpty {
          Section("Conflicts") {
            ForEach(store.conflictedChanges) { entry in
              StatusRow(entry: entry, store: store)
            }
          }
        }

        Section("Staged") {
          if store.stagedChanges.isEmpty {
            PlaceholderRow(title: "No staged changes")
          } else {
            ForEach(store.stagedChanges) { entry in
              StatusRow(entry: entry, store: store)
            }
          }
        }

        Section("Unstaged") {
          if store.unstagedChanges.isEmpty {
            PlaceholderRow(title: "No unstaged changes")
          } else {
            ForEach(store.unstagedChanges) { entry in
              StatusRow(entry: entry, store: store)
            }
          }
        }
      }
      .listStyle(.inset)

      Divider()

      CommitComposerView(store: store)
    }
  }
}

private struct StatusRow: View {
  var entry: GitStatusEntry
  let store: RepositoryStore

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: iconName)
        .foregroundStyle(iconColor)
        .frame(width: 18)

      VStack(alignment: .leading, spacing: 2) {
        Text(entry.path)
          .lineLimit(1)
        Text(entry.kind.rawValue)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      if entry.isConflicted {
        Button {
          store.presentConflictResolver(for: entry)
        } label: {
          Image(systemName: "wrench.and.screwdriver")
        }
        .buttonStyle(.borderless)
        .help("Resolve conflict")
      }

      Button {
        store.presentDiscardChange(entry)
      } label: {
        Image(systemName: "trash")
      }
      .buttonStyle(.borderless)
      .help("Discard change")

      Button {
        Task {
          if entry.isStaged {
            await store.unstage(entry)
          } else {
            await store.stage(entry)
          }
        }
      } label: {
        Image(systemName: entry.isStaged ? "minus.circle" : "plus.circle")
      }
      .buttonStyle(.borderless)
      .help(entry.isStaged ? "Unstage" : "Stage")
    }
    .contentShape(Rectangle())
    .onTapGesture {
      store.selectStatusEntry(entry)
    }
    .contextMenu {
      Button(entry.isStaged ? "Unstage" : "Stage") {
        Task {
          if entry.isStaged {
            await store.unstage(entry)
          } else {
            await store.stage(entry)
          }
        }
      }
      Button("Blame") {
        store.selectStatusEntry(entry)
        Task { await store.showBlameForSelection() }
      }
      Button("File History") {
        store.selectStatusEntry(entry)
        Task { await store.showFileHistoryForSelection() }
      }
      if store.snapshot.integrations.lfsAvailable {
        Button("Git LFS Lock") {
          store.selectStatusEntry(entry)
          Task { await store.lfsLockSelectedFile() }
        }
        Button("Git LFS Unlock") {
          store.selectStatusEntry(entry)
          Task { await store.lfsUnlockSelectedFile() }
        }
      }
      Divider()
      Button("Discard Change", role: .destructive) {
        store.presentDiscardChange(entry)
      }
      if entry.isConflicted {
        Button("Resolve Conflict") {
          store.presentConflictResolver(for: entry)
        }
      }
      Button("Reveal in Finder") {
        if let repository = store.selectedRepository {
          NSWorkspace.shared.activateFileViewerSelecting([
            URL(filePath: repository.path).appending(path: entry.path)
          ])
        }
      }
    }
  }

  private var iconName: String {
    switch entry.kind {
    case .added, .untracked:
      return "plus.circle"
    case .deleted:
      return "minus.circle"
    case .renamed, .copied:
      return "arrow.triangle.2.circlepath"
    case .conflicted:
      return "exclamationmark.triangle"
    case .modified, .typeChanged, .unknown:
      return "circle.fill"
    }
  }

  private var iconColor: Color {
    switch entry.kind {
    case .added, .untracked:
      return .green
    case .deleted:
      return .red
    case .conflicted:
      return .orange
    default:
      return .blue
    }
  }
}

private struct PlaceholderRow: View {
  var title: String

  var body: some View {
    Text(title)
      .foregroundStyle(.secondary)
  }
}

private struct CommitComposerView: View {
  @Bindable var store: RepositoryStore

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      TextEditor(text: $store.commitMessage)
        .font(.body.monospaced())
        .frame(height: 92)
        .overlay {
          RoundedRectangle(cornerRadius: 6)
            .stroke(.quaternary)
        }

      HStack {
        if !store.recentCommitMessages.isEmpty {
          Menu {
            ForEach(store.recentCommitMessages, id: \.self) { message in
              Button(message) {
                store.commitMessage = message
              }
            }
          } label: {
            Label("Recent", systemImage: "clock")
          }
          .menuStyle(.borderlessButton)
        }

        Toggle("Amend", isOn: $store.amendCommit)
        Toggle("Sign", isOn: $store.signCommit)
        Spacer()
        Button {
          Task { await store.commit() }
        } label: {
          Label(store.amendCommit ? "Amend" : "Commit", systemImage: "checkmark.circle")
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .padding(12)
  }
}
