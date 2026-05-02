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
            PlaceholderRow(title: "Nothing staged")
          } else {
            ForEach(store.stagedChanges) { entry in
              StatusRow(entry: entry, store: store)
            }
          }
        }

        Section("Unstaged") {
          if store.unstagedChanges.isEmpty {
            PlaceholderRow(title: "Nothing unstaged")
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
      ChangeStatusBadge(statusEntry: entry)

      VStack(alignment: .leading, spacing: 2) {
        Text(entry.path)
          .lineLimit(1)
        if entry.isConflicted {
          Text("Conflict needs resolution")
            .font(.caption)
            .foregroundStyle(.secondary)
        } else if let originalPath = entry.originalPath {
          Text(originalPath)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
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
        stageOrUnstage()
      } label: {
        Image(systemName: entry.isStaged ? "minus.circle" : "plus.circle")
      }
      .buttonStyle(.borderless)
      .help(entry.isStaged ? "Unstage" : "Stage")

      Menu {
        Button("Blame") {
          showBlame()
        }
        Button("File History") {
          showFileHistory()
        }
        if store.snapshot.integrations.lfsAvailable {
          Divider()
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
        Button("Reveal in Finder") {
          revealInFinder()
        }
        Button("Discard Change", role: .destructive) {
          store.presentDiscardChange(entry)
        }
      } label: {
        Image(systemName: "ellipsis.circle")
      }
      .menuStyle(.borderlessButton)
      .help("File actions")
      .accessibilityLabel("File actions for \(entry.path)")
    }
    .contentShape(Rectangle())
    .onTapGesture {
      store.selectStatusEntry(entry)
    }
    .contextMenu {
      Button(entry.isStaged ? "Unstage" : "Stage") {
        stageOrUnstage()
      }
      Button("Blame") {
        showBlame()
      }
      Button("File History") {
        showFileHistory()
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
        revealInFinder()
      }
    }
  }

  private func stageOrUnstage() {
    Task {
      if entry.isStaged {
        await store.unstage(entry)
      } else {
        await store.stage(entry)
      }
    }
  }

  private func showBlame() {
    store.selectStatusEntry(entry)
    Task { await store.showBlameForSelection() }
  }

  private func showFileHistory() {
    store.selectStatusEntry(entry)
    Task { await store.showFileHistoryForSelection() }
  }

  private func revealInFinder() {
    if let repository = store.selectedRepository {
      NSWorkspace.shared.activateFileViewerSelecting([
        URL(filePath: repository.path).appending(path: entry.path)
      ])
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
      ZStack(alignment: .topLeading) {
        TextEditor(text: $store.commitMessage)
          .font(.body.monospaced())
          .frame(height: 92)

        if store.commitMessage.isEmpty {
          Text("Commit message")
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .allowsHitTesting(false)
        }
      }
      .overlay {
        RoundedRectangle(cornerRadius: 6)
          .stroke(.quaternary)
      }

      HStack(spacing: 8) {
        if !store.recentCommitMessages.isEmpty {
          Menu {
            ForEach(store.recentCommitMessages, id: \.self) { message in
              Button(message) {
                store.commitMessage = message
              }
            }
          } label: {
            Label("Recent messages", systemImage: "clock")
              .lineLimit(1)
          }
          .menuStyle(.borderlessButton)
        }

        Menu {
          Toggle("Amend Last Commit", isOn: $store.amendCommit)
          Toggle("Sign Commit", isOn: $store.signCommit)
        } label: {
          Label("Commit settings", systemImage: "slider.horizontal.3")
            .lineLimit(1)
        }
        .menuStyle(.borderlessButton)
        .help(commitOptionsHelp)

        if !commitOptionsSummary.isEmpty {
          Text(commitOptionsSummary)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .help(commitOptionsHelp)
        }

        Spacer()

        Button {
          Task { await store.commit() }
        } label: {
          Label(store.amendCommit ? "Amend commit" : "Commit", systemImage: "checkmark.circle")
            .lineLimit(1)
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .padding(12)
  }

  private var commitOptionsSummary: String {
    switch (store.amendCommit, store.signCommit) {
    case (true, true):
      return "Amend, signed"
    case (true, false):
      return "Amend"
    case (false, true):
      return "Signed"
    case (false, false):
      return ""
    }
  }

  private var commitOptionsHelp: String {
    if commitOptionsSummary.isEmpty {
      return "Commit options"
    }
    return "Commit options: \(commitOptionsSummary)"
  }
}
