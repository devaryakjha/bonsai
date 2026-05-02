import AppKit
import SwiftUI

struct DetailView: View {
  let store: RepositoryStore
  @State private var diffSearchText = ""
  @State private var isDiffSearchVisible = false

  var body: some View {
    VStack(spacing: 0) {
      DetailHeaderView(
        store: store,
        diffSearchText: $diffSearchText,
        isDiffSearchVisible: $isDiffSearchVisible
      )
      Divider()
      DiffView(store: store, searchText: diffSearchText)
      if let result = store.commandResult {
        Divider()
        CommandResultView(result: result) {
          store.commandResult = nil
        }
        .id(result.id)
      }
    }
    .focusedSceneValue(\.diffFindVisible, $isDiffSearchVisible)
  }
}

private struct DetailHeaderView: View {
  let store: RepositoryStore
  @Binding var diffSearchText: String
  @Binding var isDiffSearchVisible: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 5) {
          titleView
        }

        Spacer(minLength: 16)

        DiffHeaderControls(
          store: store,
          searchText: $diffSearchText,
          isSearchVisible: $isDiffSearchVisible
        )
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
  }

  @ViewBuilder
  private var titleView: some View {
    if let file = store.selectedChangedFile, store.mainMode == .history {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        ChangeStatusBadge(changedFile: file)
        Text(file.path)
          .font(.headline)
          .lineLimit(2)
          .truncationMode(.middle)
          .help(file.oldPath.map { "\($0) -> \(file.path)" } ?? file.path)
      }
      selectedChangedFileContext(file)
        .font(.caption)
        .foregroundStyle(.secondary)
    } else if let stash = store.selectedStash, store.mainMode == .history {
      Text(stash.index)
        .font(.headline)
        .lineLimit(1)
      Text(stash.message)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    } else if let entry = store.selectedTreeEntry, let commit = store.selectedCommit, store.mainMode == .history {
      Text(entry.path)
        .font(.headline)
        .lineLimit(2)
        .truncationMode(.middle)
        .help(entry.path)
      HStack(spacing: 8) {
        Text(commit.shortHash)
          .monospaced()
        Text(entry.kindTitle)
        Text(entry.mode)
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    } else if let commit = store.selectedCommit, store.mainMode == .history {
      Text(commit.subject)
        .font(.headline)
        .lineLimit(2)
      HStack(spacing: 8) {
        Text(commit.shortHash)
          .monospaced()
        Text(commit.authorName)
        if let date = commit.date {
          Text(date, style: .date)
          Text(date, style: .time)
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    } else if let entry = store.selectedStatusEntry {
      Text(entry.path)
        .font(.headline)
        .lineLimit(2)
        .truncationMode(.middle)
        .help(entry.path)
      HStack(spacing: 8) {
        ChangeStatusBadge(statusEntry: entry)
        if entry.isStaged {
          Text("Staged")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    } else {
      Text(DiffEmptyStateCopy.title)
        .font(.headline)
    }
  }

  @ViewBuilder
  private func selectedChangedFileContext(_ file: GitChangedFile) -> some View {
    if let stash = store.selectedStash {
      HStack(spacing: 8) {
        Text(stash.index)
          .monospaced()
        Text(stash.message)
          .lineLimit(1)
      }
      .help(file.oldPath.map { "Renamed from \($0)" } ?? stash.message)
    } else if let commit = store.selectedCommit {
      HStack(spacing: 8) {
        Text(commit.shortHash)
          .monospaced()
        Text(commit.subject)
          .lineLimit(1)
      }
      .help(file.oldPath.map { "Renamed from \($0)" } ?? commit.subject)
    } else if let oldPath = file.oldPath {
      Text("Renamed from \(oldPath)")
        .lineLimit(1)
    }
  }
}

private struct DiffHeaderControls: View {
  let store: RepositoryStore
  @Binding var searchText: String
  @Binding var isSearchVisible: Bool

  var body: some View {
    HStack(spacing: 8) {
      Button {
        if isSearchVisible {
          searchText = ""
        }
        isSearchVisible.toggle()
      } label: {
        Label("Find", systemImage: "magnifyingglass")
          .labelStyle(.iconOnly)
      }
      .controlSize(.small)
      .help(isSearchVisible ? "Hide find" : "Find in diff")
      .accessibilityLabel(isSearchVisible ? "Hide find" : "Find in diff")
      .disabled(!canFindDiff)

      if isSearchVisible {
        TextField("Find", text: $searchText)
          .textFieldStyle(.roundedBorder)
          .controlSize(.small)
          .frame(width: 180)
          .accessibilityLabel("Find in diff")

        if let matchLabel {
          Text(matchLabel)
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .lineLimit(1)
            .frame(minWidth: 72, alignment: .leading)
        }
      }

      Picker("Diff view", selection: Binding(
        get: { store.diffDisplayMode },
        set: { store.diffDisplayMode = $0 }
      )) {
        ForEach(DiffDisplayMode.allCases) { mode in
          Text(mode.title).tag(mode)
        }
      }
      .pickerStyle(.segmented)
      .controlSize(.small)
      .labelsHidden()
      .accessibilityLabel("Diff view")
      .frame(width: 150)

      Menu {
        if let summary {
          Section("Summary") {
            Label("\(summary.additions.formatted()) added", systemImage: "plus")
            Label("\(summary.deletions.formatted()) removed", systemImage: "minus")
            Label("\(summary.hunkCount.formatted()) hunks", systemImage: "text.alignleft")
            if summary.isMetadataOnly {
              Label("Metadata-only change", systemImage: "info.circle")
            }
          }
        }
        Section("Algorithm") {
          ForEach(DiffAlgorithm.allCases) { algorithm in
            Button {
              store.diffAlgorithm = algorithm
            } label: {
              if store.diffAlgorithm == algorithm {
                Label(algorithm.title, systemImage: "checkmark")
              } else {
                Text(algorithm.title)
              }
            }
          }
        }
        Section("Whitespace") {
          ForEach(DiffWhitespaceMode.allCases) { mode in
            Button {
              store.diffWhitespaceMode = mode
            } label: {
              if store.diffWhitespaceMode == mode {
                Label(mode.title, systemImage: "checkmark")
              } else {
                Text(mode.title)
              }
            }
          }
        }
      } label: {
        Label("Diff options", systemImage: "slider.horizontal.3")
      }
      .controlSize(.small)
      .help("Diff options")

      Button {
        store.copyCurrentPatch()
      } label: {
        Label("Copy patch", systemImage: "doc.on.doc")
          .labelStyle(.iconOnly)
      }
      .controlSize(.small)
      .help("Copy patch")
      .accessibilityLabel("Copy patch")
      .disabled(!store.canCopyCurrentPatch)
    }
    .fixedSize()
  }

  private var summary: DiffSummary? {
    let diffText = store.diffText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !diffText.isEmpty else { return nil }
    return DiffSummary(diffText: store.diffText, hunkCount: store.diffHunks.count)
  }

  private var canFindDiff: Bool {
    !store.diffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var matchLabel: String? {
    DiffSearch.matchLabel(query: searchText) {
      searchableText
    }
  }

  private var searchableText: String {
    switch store.diffDisplayMode {
    case .unified:
      return DiffSearch.visibleUnifiedText(from: store.diffText)
    case .split:
      return DiffSearch.visibleSplitText(from: store.splitDiff)
    }
  }
}

private struct DiffView: View {
  let store: RepositoryStore
  var searchText: String

  var body: some View {
    VStack(spacing: 0) {
      if let entry = store.selectedTreeEntry {
        TreeBlobPreview(path: entry.path, text: store.treeBlobText)
      } else if store.diffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        ContentUnavailableView(
          DiffEmptyStateCopy.title,
          systemImage: DiffEmptyStateCopy.systemImage
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        if shouldShowHunks {
          HunkActionStrip(
            hunks: store.diffHunks,
            lineChanges: store.diffLineChanges,
            isStaged: store.selectedStatusEntry?.isStaged == true,
            onSelectHunk: { hunk in
              Task {
                if store.selectedStatusEntry?.isStaged == true {
                  await store.unstageHunk(hunk)
                } else {
                  await store.stageHunk(hunk)
                }
              }
            },
            onSelectLine: { change in
              Task {
                if store.selectedStatusEntry?.isStaged == true {
                  await store.unstageLineChange(change)
                } else {
                  await store.stageLineChange(change)
                }
              }
            },
            onShowLineHistory: { change in
              Task { await store.showLineHistory(change) }
            },
            onShowHunkHistory: { hunk in
              Task { await store.showHunkHistory(hunk) }
            },
            onDiscardHunk: { hunk in
              store.presentDiscardHunk(hunk)
            },
            onDiscardLine: { change in
              store.presentDiscardLineChange(change)
            }
          )
          Divider()
        }

        if store.selectedDiffIsBinary || store.selectedPreviewIsImage {
          BinaryPreviewView(store: store)
        } else {
          switch store.diffDisplayMode {
          case .unified:
            RichDiffTextView(text: store.diffText, searchText: searchText)
          case .split:
            SplitDiffViewer(splitDiff: store.splitDiff, paneContext: splitPaneContext, searchText: searchText)
          }
        }
      }
    }
  }

  private var shouldShowHunks: Bool {
    store.selectedStatusEntry != nil && !store.diffHunks.isEmpty
  }

  private var splitPaneContext: SplitDiffPaneContext {
    if let entry = store.selectedStatusEntry {
      return .workingTree(entry: entry)
    }
    if let file = store.selectedChangedFile {
      if let stash = store.selectedStash {
        return .changedFile(file, oldTitle: "Base", newTitle: stash.index)
      }
      if let commit = store.selectedCommit {
        return .changedFile(file, oldTitle: "Parent", newTitle: commit.shortHash)
      }
      return .changedFile(file, oldTitle: "Before", newTitle: "After")
    }
    return .fallback
  }
}

private struct SplitDiffViewer: View {
  var splitDiff: SplitDiff
  var paneContext: SplitDiffPaneContext
  var searchText: String

  var body: some View {
    SplitDiffTextView(splitDiff: splitDiff, paneContext: paneContext, searchText: searchText)
  }
}

private struct TreeBlobPreview: View {
  var path: String
  var text: String

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Image(systemName: "doc.text")
        Text(path)
          .lineLimit(1)
          .truncationMode(.middle)
          .help(path)
        Spacer()
      }
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      RichDiffTextView(text: text)
    }
  }
}

private struct BinaryPreviewView: View {
  let store: RepositoryStore

  var body: some View {
    VStack(spacing: 0) {
      if let snapshot = store.imageDiffSnapshot {
        BinaryPreviewHeader(store: store)
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
        Divider()
        HStack(spacing: 0) {
          ImageDiffPane(side: .before, data: snapshot.oldData)
          Divider()
          ImageDiffPane(side: .after, data: snapshot.newData)
        }
      } else {
        VStack(spacing: 12) {
          Image(systemName: previewCopy.systemImage)
            .font(.system(size: 44))
            .foregroundStyle(.secondary)

          Text(previewCopy.title)
            .font(.title3)
            .fontWeight(.semibold)

          BinaryPreviewHeader(store: store)
            .frame(maxWidth: 520)

          if !store.diffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(store.diffText)
              .font(.caption.monospaced())
              .foregroundStyle(.secondary)
              .textSelection(.enabled)
              .padding()
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var previewCopy: BinaryPreviewCopy {
    BinaryPreviewCopy(isImage: store.selectedPreviewIsImage, statusTitle: store.selectedPreviewStatusTitle)
  }
}

private struct BinaryPreviewHeader: View {
  let store: RepositoryStore

  var body: some View {
    VStack(spacing: 5) {
      HStack(spacing: 8) {
        statusBadge
        Text(previewCopy.statusLine)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .center)

      Text(previewPath)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
        .truncationMode(.middle)
        .multilineTextAlignment(.center)
        .help(previewPath)
    }
  }

  @ViewBuilder
  private var statusBadge: some View {
    if let entry = store.selectedStatusEntry {
      ChangeStatusBadge(statusEntry: entry)
    } else if let file = store.selectedChangedFile {
      ChangeStatusBadge(changedFile: file)
    }
  }

  private var previewCopy: BinaryPreviewCopy {
    BinaryPreviewCopy(isImage: store.selectedPreviewIsImage, statusTitle: store.selectedPreviewStatusTitle)
  }

  private var previewPath: String {
    store.selectedPreviewPath ?? "No file selected"
  }
}

private struct ImageDiffPane: View {
  var side: ImageDiffPaneSide
  var data: Data?

  var body: some View {
    VStack(spacing: 10) {
      Text(side.title)
        .font(.headline)
      if let data, let image = NSImage(data: data) {
        Image(nsImage: image)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
        Text(ImageDiffMetadata.metadata(for: image, data: data))
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
      } else {
        ContentUnavailableView(
          side.missingTitle,
          systemImage: "photo"
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

private struct HunkActionStrip: View {
  var hunks: [DiffHunk]
  var lineChanges: [DiffLineChange]
  var isStaged: Bool
  var onSelectHunk: (DiffHunk) -> Void
  var onSelectLine: (DiffLineChange) -> Void
  var onShowLineHistory: (DiffLineChange) -> Void
  var onShowHunkHistory: (DiffHunk) -> Void
  var onDiscardHunk: (DiffHunk) -> Void
  var onDiscardLine: (DiffLineChange) -> Void

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        hunkActions

        if !lineChanges.isEmpty {
          Divider()
            .frame(height: 18)

          Menu {
            ForEach(lineChanges) { change in
              Button(change.title) {
                onSelectLine(change)
              }
            }
          } label: {
            Label(isStaged ? "Unstage line" : "Stage line", systemImage: "text.line.first.and.arrowtriangle.forward")
          }
          .menuStyle(.borderedButton)
          .controlSize(.small)
        }

        Menu {
          if !hunksWithHistory.isEmpty {
            Section("Hunks") {
              ForEach(hunksWithHistory, id: \.hunk.id) { item in
                Button("Hunk \(item.hunk.id + 1), \(item.range.title)") {
                  onShowHunkHistory(item.hunk)
                }
              }
            }
          }

          if !lineChanges.isEmpty {
            Section("Lines") {
              ForEach(lineChanges) { change in
                Button(change.historyTitle) {
                  onShowLineHistory(change)
                }
              }
            }
          }
        } label: {
          Label("History", systemImage: "clock.arrow.circlepath")
        }
        .menuStyle(.borderedButton)
        .controlSize(.small)
        .disabled(hunksWithHistory.isEmpty && lineChanges.isEmpty)
        .help("Show hunk or line history")

        if !isStaged {
          Menu {
            Section("Hunks") {
              ForEach(hunks) { hunk in
                Button("Hunk \(hunk.id + 1)", role: .destructive) {
                  onDiscardHunk(hunk)
                }
              }
            }

            if !lineChanges.isEmpty {
              Section("Lines") {
                ForEach(lineChanges) { change in
                  Button(change.title, role: .destructive) {
                    onDiscardLine(change)
                  }
                }
              }
            }
          } label: {
            Label("Discard", systemImage: "trash")
          }
          .menuStyle(.borderedButton)
          .controlSize(.small)
          .help("Discard part of this change")
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
    }
  }

  private var hunksWithHistory: [(hunk: DiffHunk, range: DiffHunkHistoryRange)] {
    hunks.compactMap { hunk in
      guard let range = DiffHunkHistoryRange.range(for: hunk) else { return nil }
      return (hunk, range)
    }
  }

  @ViewBuilder
  private var hunkActions: some View {
    if hunks.count == 1, let hunk = hunks.first {
      Button {
        onSelectHunk(hunk)
      } label: {
        Label(hunkActionTitle(for: hunk), systemImage: hunkActionSystemImage)
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
      .help(hunk.header)
    } else {
      Menu {
        ForEach(hunks) { hunk in
          Button(hunkActionTitle(for: hunk)) {
            onSelectHunk(hunk)
          }
          .help(hunk.header)
        }
      } label: {
        Label(isStaged ? "Unstage hunk" : "Stage hunk", systemImage: hunkActionSystemImage)
      }
      .menuStyle(.borderedButton)
      .controlSize(.small)
      .help(isStaged ? "Unstage a hunk" : "Stage a hunk")
    }
  }

  private var hunkActionSystemImage: String {
    isStaged ? "minus.circle" : "plus.circle"
  }

  private func hunkActionTitle(for hunk: DiffHunk) -> String {
    "\(isStaged ? "Unstage" : "Stage") hunk \(hunk.id + 1)"
  }
}

private struct DiffSummary {
  var additions = 0
  var deletions = 0
  var hunkCount = 0

  init(diffText: String, hunkCount: Int) {
    self.hunkCount = hunkCount
    for line in diffText.split(separator: "\n", omittingEmptySubsequences: false) {
      if line.hasPrefix("+") && !line.hasPrefix("+++") {
        additions += 1
      } else if line.hasPrefix("-") && !line.hasPrefix("---") {
        deletions += 1
      }
    }
  }

  var isMetadataOnly: Bool {
    additions == 0 && deletions == 0
  }
}

private struct CommandResultView: View {
  var result: CommandResult
  var onDismiss: () -> Void
  @State private var isExpanded: Bool

  init(result: CommandResult, onDismiss: @escaping () -> Void) {
    self.result = result
    self.onDismiss = onDismiss
    _isExpanded = State(initialValue: result.isError)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        statusIcon
        DisclosureGroup(isExpanded: $isExpanded) {
          Text(result.output)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(8)
            .textSelection(.enabled)
            .padding(.top, 6)
        } label: {
          VStack(alignment: .leading, spacing: 2) {
            Text(result.title)
              .font(.subheadline.weight(.semibold))
              .lineLimit(1)
              .truncationMode(.middle)
              .help(result.title)
              .accessibilityLabel(result.title)
            Text(result.summary)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .truncationMode(.tail)
              .help(result.summary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        Spacer(minLength: 8)

        Button {
          onDismiss()
        } label: {
          Image(systemName: "xmark")
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .help("Dismiss output")
        .accessibilityLabel("Dismiss command output")
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(.bar)
  }

  private var statusIcon: some View {
    Image(systemName: result.isError ? "exclamationmark.triangle" : "checkmark.circle")
      .foregroundStyle(result.isError ? .orange : .green)
      .frame(width: 16)
  }
}
