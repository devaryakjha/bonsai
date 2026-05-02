import AppKit
import SwiftUI

struct DetailView: View {
  let store: RepositoryStore

  var body: some View {
    VStack(spacing: 0) {
      DetailHeaderView(store: store)
      Divider()
      DiffView(store: store)
      if let result = store.commandResult {
        Divider()
        CommandResultView(result: result) {
          store.commandResult = nil
        }
        .id(result.id)
      }
    }
  }
}

private struct DetailHeaderView: View {
  let store: RepositoryStore

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 5) {
          titleView
        }

        Spacer(minLength: 16)

        DiffHeaderControls(store: store)
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
      HStack(spacing: 8) {
        Text(commit.shortHash)
          .monospaced()
        Text(entry.kind.rawValue)
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
      HStack(spacing: 8) {
        ChangeStatusBadge(statusEntry: entry)
        if entry.isStaged {
          Text("Staged")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    } else {
      Text("Diff")
        .font(.headline)
      Text("Select a commit file or working tree change")
        .font(.caption)
        .foregroundStyle(.secondary)
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

  var body: some View {
    HStack(spacing: 8) {
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
}

private struct DiffView: View {
  let store: RepositoryStore

  var body: some View {
    VStack(spacing: 0) {
      if let entry = store.selectedTreeEntry {
        TreeBlobPreview(path: entry.path, text: store.treeBlobText)
      } else if store.diffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        ContentUnavailableView(
          "No diff selected",
          systemImage: "doc.text.magnifyingglass",
          description: Text("Choose a file or working tree change to inspect it here.")
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
            }
          )
          Divider()
        }

        if store.selectedDiffIsBinary || store.selectedPreviewIsImage {
          BinaryPreviewView(store: store)
        } else {
          switch store.diffDisplayMode {
          case .unified:
            RichDiffTextView(text: store.diffText)
          case .split:
            SplitDiffViewer(splitDiff: store.splitDiff, paneContext: splitPaneContext)
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

  var body: some View {
    SplitDiffTextView(splitDiff: splitDiff, paneContext: paneContext)
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
    VStack(spacing: 16) {
      if let snapshot = store.imageDiffSnapshot {
        HStack(spacing: 0) {
          ImageDiffPane(title: "Before", data: snapshot.oldData)
          Divider()
          ImageDiffPane(title: "After", data: snapshot.newData)
        }
      } else {
        Image(systemName: store.selectedPreviewIsImage ? "photo" : "doc")
          .font(.system(size: 48))
          .foregroundStyle(.secondary)

        Text(store.selectedPreviewIsImage ? "Image diff" : "Binary diff")
          .font(.title3)
          .fontWeight(.semibold)

        Text(store.selectedPreviewPath ?? "No file selected")
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
          .multilineTextAlignment(.center)

        if !store.diffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text(store.diffText)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .padding()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

}

private struct ImageDiffPane: View {
  var title: String
  var data: Data?

  var body: some View {
    VStack(spacing: 10) {
      Text(title)
        .font(.headline)
      if let data, let image = NSImage(data: data) {
        Image(nsImage: image)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
        Text(Self.metadata(for: image, data: data))
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
      } else {
        ContentUnavailableView(
          "No image",
          systemImage: "photo",
          description: Text("This side is not available for the selected change.")
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private static func metadata(for image: NSImage, data: Data) -> String {
    let size = image.size
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return "\(Int(size.width)) x \(Int(size.height)) - \(formatter.string(fromByteCount: Int64(data.count)))"
  }
}

private struct HunkActionStrip: View {
  var hunks: [DiffHunk]
  var lineChanges: [DiffLineChange]
  var isStaged: Bool
  var onSelectHunk: (DiffHunk) -> Void
  var onSelectLine: (DiffLineChange) -> Void
  var onShowLineHistory: (DiffLineChange) -> Void

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        ForEach(hunks) { hunk in
          Button {
            onSelectHunk(hunk)
          } label: {
            Label(isStaged ? "Unstage hunk \(hunk.id + 1)" : "Stage hunk \(hunk.id + 1)", systemImage: isStaged ? "minus.circle" : "plus.circle")
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
          .help(hunk.header)
        }

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

          Menu {
            ForEach(lineChanges) { change in
              Button(change.historyTitle) {
                onShowLineHistory(change)
              }
            }
          } label: {
            Label("Line history", systemImage: "clock.arrow.circlepath")
          }
          .menuStyle(.borderedButton)
          .controlSize(.small)
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
    }
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
            Text(summary)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
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

  private var summary: String {
    let trimmed = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return result.isError ? "Failed" : "Completed" }
    return trimmed.components(separatedBy: .newlines).first ?? trimmed
  }
}
