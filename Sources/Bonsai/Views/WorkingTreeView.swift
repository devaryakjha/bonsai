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

        Section {
          if store.stagedChanges.isEmpty {
            PlaceholderRow(title: "Nothing staged")
          } else {
            ForEach(store.stagedChanges) { entry in
              StatusRow(entry: entry, store: store)
            }
          }
        } header: {
          WorkingTreeSectionHeader(
            title: "Staged",
            actionSystemImage: "minus.circle",
            actionTitle: "Unstage all",
            isActionAvailable: store.canUnstageAll
          ) {
            Task { await store.unstageAll() }
          }
        }

        Section {
          if store.unstagedChanges.isEmpty {
            PlaceholderRow(title: "Nothing unstaged")
          } else {
            ForEach(store.unstagedChanges) { entry in
              StatusRow(entry: entry, store: store)
            }
          }
        } header: {
          WorkingTreeSectionHeader(
            title: "Unstaged",
            actionSystemImage: "plus.circle",
            actionTitle: "Stage all",
            isActionAvailable: store.canStageAll,
            action: {
              Task { await store.stageAll() }
            },
            secondaryActionSystemImage: store.showIgnoredFiles ? "eye.slash" : "eye",
            secondaryActionTitle: store.showIgnoredFiles ? "Hide ignored files" : "Show ignored files",
            secondaryAction: {
              store.toggleIgnoredFiles()
            }
          )
        }

        if store.showIgnoredFiles {
          Section {
            if store.ignoredChanges.isEmpty {
              PlaceholderRow(title: "No ignored files")
            } else {
              ForEach(store.ignoredChanges) { entry in
                IgnoredStatusRow(entry: entry, store: store)
              }
            }
          } header: {
            Text("Ignored")
          }
        }
      }
      .listStyle(.inset)

      Divider()

      CommitComposerView(store: store)
    }
  }
}

private struct WorkingTreeSectionHeader: View {
  var title: String
  var actionSystemImage: String
  var actionTitle: String
  var isActionAvailable: Bool
  var action: () -> Void
  var secondaryActionSystemImage: String?
  var secondaryActionTitle: String?
  var secondaryAction: (() -> Void)?

  init(
    title: String,
    actionSystemImage: String,
    actionTitle: String,
    isActionAvailable: Bool,
    action: @escaping () -> Void,
    secondaryActionSystemImage: String? = nil,
    secondaryActionTitle: String? = nil,
    secondaryAction: (() -> Void)? = nil
  ) {
    self.title = title
    self.actionSystemImage = actionSystemImage
    self.actionTitle = actionTitle
    self.isActionAvailable = isActionAvailable
    self.action = action
    self.secondaryActionSystemImage = secondaryActionSystemImage
    self.secondaryActionTitle = secondaryActionTitle
    self.secondaryAction = secondaryAction
  }

  var body: some View {
    HStack(spacing: 8) {
      Text(title)
        .lineLimit(1)

      Spacer(minLength: 8)

      if isActionAvailable {
        Button(action: action) {
          Image(systemName: actionSystemImage)
            .imageScale(.medium)
        }
        .buttonStyle(.borderless)
        .help(actionTitle)
        .accessibilityLabel(actionTitle)
      }

      if let secondaryActionSystemImage,
         let secondaryActionTitle,
         let secondaryAction {
        Button(action: secondaryAction) {
          Image(systemName: secondaryActionSystemImage)
            .imageScale(.medium)
        }
        .buttonStyle(.borderless)
        .help(secondaryActionTitle)
        .accessibilityLabel(secondaryActionTitle)
      }
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
          .truncationMode(.middle)
          .help(entry.path)
        if entry.isConflicted {
          Text("Conflict needs resolution")
            .font(.caption)
            .foregroundStyle(.secondary)
        } else if let originalPath = entry.originalPath {
          Text(originalPath)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .help(originalPath)
        }
      }

      Spacer()

      Button {
        runPrimaryAction()
      } label: {
        Image(systemName: entry.primaryRowAction.systemImage)
      }
      .buttonStyle(.borderless)
      .help(entry.primaryRowAction.title)
      .accessibilityLabel("\(entry.primaryRowAction.title) \(entry.path)")

      Menu {
        if entry.isConflicted {
          Button("Resolve Conflict") {
            resolveConflict()
          }
        }
        Button(entry.isStaged ? "Unstage" : "Stage") {
          stageOrUnstage()
        }
        Divider()
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
          Button("Git LFS Force Unlock") {
            store.selectStatusEntry(entry)
            Task { await store.lfsUnlockSelectedFile(force: true) }
          }
        }
        Divider()
        Button("Copy Path") {
          copyPath()
        }
        Button("Copy Absolute Path") {
          copyAbsolutePath()
        }
        Button("Open") {
          openFile()
        }
        Menu("Open In") {
          ForEach(ExternalEditor.allCases) { editor in
            Button(editor.title) {
              store.openFile(path: entry.path, in: editor)
            }
          }
        }
        Button("Reveal in Finder") {
          revealInFinder()
        }
        if entry.isUntracked {
          Divider()
          Button("Ignore") {
            ignoreFile()
          }
          if canIgnoreExtension {
            Button("Ignore Extension") {
              ignoreExtension()
            }
          }
          if canIgnoreDirectory {
            Button("Ignore Folder") {
              ignoreDirectory()
            }
          }
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
      if entry.isConflicted {
        Button("Resolve Conflict") {
          resolveConflict()
        }
      }
      Button(entry.isStaged ? "Unstage" : "Stage") {
        stageOrUnstage()
      }
      Divider()
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
        Button("Git LFS Force Unlock") {
          store.selectStatusEntry(entry)
          Task { await store.lfsUnlockSelectedFile(force: true) }
        }
      }
      Divider()
      Button("Copy Path") {
        copyPath()
      }
      Button("Copy Absolute Path") {
        copyAbsolutePath()
      }
      Button("Open") {
        openFile()
      }
      Button("Reveal in Finder") {
        revealInFinder()
      }
      if entry.isUntracked {
        Button("Ignore") {
          ignoreFile()
        }
        if canIgnoreExtension {
          Button("Ignore Extension") {
            ignoreExtension()
          }
        }
        if canIgnoreDirectory {
          Button("Ignore Folder") {
            ignoreDirectory()
          }
        }
      }
      Divider()
      Button("Discard Change", role: .destructive) {
        store.presentDiscardChange(entry)
      }
    }
  }

  private func runPrimaryAction() {
    switch entry.primaryRowAction {
    case .stage, .unstage:
      stageOrUnstage()
    case .resolveConflict:
      resolveConflict()
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

  private func resolveConflict() {
    Task { await store.presentConflictResolver(for: entry) }
  }

  private func copyPath() {
    PasteboardWriter.copy(entry.path)
  }

  private func copyAbsolutePath() {
    store.copyAbsoluteFilePath(path: entry.path)
  }

  private func openFile() {
    store.openFile(path: entry.path)
  }

  private func revealInFinder() {
    store.revealInFinder(path: entry.path)
  }

  private func ignoreFile() {
    Task { await store.ignore(entry) }
  }

  private func ignoreExtension() {
    Task { await store.ignoreExtension(entry) }
  }

  private func ignoreDirectory() {
    Task { await store.ignoreDirectory(entry) }
  }

  private var canIgnoreExtension: Bool {
    entry.isUntracked && GitIgnorePattern.extensionPattern(for: entry.path) != nil
  }

  private var canIgnoreDirectory: Bool {
    entry.isUntracked && GitIgnorePattern.directoryPattern(for: entry.path) != nil
  }
}

private struct IgnoredStatusRow: View {
  var entry: GitStatusEntry
  let store: RepositoryStore

  var body: some View {
    HStack(spacing: 10) {
      ChangeStatusBadge(statusEntry: entry)

      Text(entry.path)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .truncationMode(.middle)
        .help(entry.path)

      Spacer()
    }
    .contextMenu {
      Button("Copy Path") {
        PasteboardWriter.copy(entry.path)
      }
      Button("Copy Absolute Path") {
        store.copyAbsoluteFilePath(path: entry.path)
      }
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
              Button(RecentCommitMessagePreview.title(for: message)) {
                store.commitMessage = message
              }
            }
            Divider()
            Button("Clear Recent Messages", role: .destructive) {
              store.clearRecentCommitMessages()
            }
          } label: {
            Label("Recent messages", systemImage: "clock")
              .labelStyle(.iconOnly)
              .lineLimit(1)
          }
          .menuStyle(.borderlessButton)
          .help("Recent commit messages")
          .accessibilityLabel("Recent commit messages")
        }

        Menu {
          Toggle("Amend Last Commit", isOn: $store.amendCommit)
          Toggle("Sign Commit", isOn: $store.signCommit)
        } label: {
          Label("Commit settings", systemImage: "slider.horizontal.3")
            .labelStyle(.iconOnly)
            .lineLimit(1)
        }
        .menuStyle(.borderlessButton)
        .help(commitOptionsHelp)
        .accessibilityLabel("Commit settings")

        Button {
          Task { await store.generateCommitMessageWithClaude() }
        } label: {
          Label("Generate commit message", systemImage: "sparkles")
            .labelStyle(.iconOnly)
            .lineLimit(1)
        }
        .buttonStyle(.borderless)
        .disabled(!store.canGenerateCommitMessageWithClaude)
        .help(store.generateCommitMessageWithClaudeHelp)
        .accessibilityLabel("Generate commit message")

        if !store.commitOptionsSummary.isEmpty {
          Text(store.commitOptionsSummary)
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
        .disabled(!store.canCommit)
        .help(store.commitReadinessIssue ?? (store.amendCommit ? "Amend commit" : "Create commit"))
      }
    }
    .padding(12)
  }

  private var commitOptionsHelp: String {
    if store.commitOptionsSummary.isEmpty {
      return "Commit options"
    }
    return "Commit options: \(store.commitOptionsSummary)"
  }
}
