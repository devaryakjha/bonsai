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
        CommandResultView(result: result)
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

        VStack(alignment: .trailing, spacing: 8) {
          Picker("Algorithm", selection: Binding(
            get: { store.diffAlgorithm },
            set: { store.diffAlgorithm = $0 }
          )) {
            ForEach(DiffAlgorithm.allCases) { algorithm in
              Text(algorithm.title).tag(algorithm)
            }
          }
          .pickerStyle(.segmented)
          .controlSize(.small)
          .frame(width: 300)

          Picker("View", selection: Binding(
            get: { store.diffDisplayMode },
            set: { store.diffDisplayMode = $0 }
          )) {
            ForEach(DiffDisplayMode.allCases) { mode in
              Text(mode.title).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .controlSize(.small)
          .frame(width: 168)
        }
      }

      if !store.diffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        DiffSummaryStrip(summary: DiffSummary(diffText: store.diffText, hunkCount: store.diffHunks.count))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
  }

  @ViewBuilder
  private var titleView: some View {
    if let commit = store.selectedCommit, store.mainMode == .history {
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
        Text(entry.kind.rawValue)
        if entry.isStaged {
          Text("Staged")
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    } else {
      Text("Diff")
        .font(.headline)
      Text("Select a commit file or working tree change")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

private struct DiffView: View {
  let store: RepositoryStore

  var body: some View {
    VStack(spacing: 0) {
      if store.diffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        ContentUnavailableView(
          "No Diff Selected",
          systemImage: "doc.text.magnifyingglass",
          description: Text("Choose a file or working tree change to inspect it here.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        if shouldShowHunks {
          HunkActionStrip(
            hunks: store.diffHunks,
            isStaged: store.selectedStatusEntry?.isStaged == true,
            onSelect: { hunk in
              Task {
                if store.selectedStatusEntry?.isStaged == true {
                  await store.unstageHunk(hunk)
                } else {
                  await store.stageHunk(hunk)
                }
              }
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
            SplitDiffTextView(splitDiff: store.splitDiff)
          }
        }
      }
    }
  }

  private var shouldShowHunks: Bool {
    store.selectedStatusEntry != nil && !store.diffHunks.isEmpty
  }
}

private struct BinaryPreviewView: View {
  let store: RepositoryStore

  var body: some View {
    VStack(spacing: 16) {
      if let image = workingTreeImage {
        Image(nsImage: image)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
      } else {
        Image(systemName: store.selectedPreviewIsImage ? "photo" : "doc")
          .font(.system(size: 48))
          .foregroundStyle(.secondary)

        Text(store.selectedPreviewIsImage ? "Image Diff" : "Binary Diff")
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

  private var workingTreeImage: NSImage? {
    guard let url = store.selectedWorkingTreeImageURL else { return nil }
    return NSImage(contentsOf: url)
  }
}

private struct HunkActionStrip: View {
  var hunks: [DiffHunk]
  var isStaged: Bool
  var onSelect: (DiffHunk) -> Void

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        ForEach(hunks) { hunk in
          Button {
            onSelect(hunk)
          } label: {
            Label(isStaged ? "Unstage Hunk \(hunk.id + 1)" : "Stage Hunk \(hunk.id + 1)", systemImage: isStaged ? "minus.circle" : "plus.circle")
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
          .help(hunk.header)
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
    }
  }
}

private struct DiffSummaryStrip: View {
  var summary: DiffSummary

  var body: some View {
    HStack(spacing: 8) {
      DiffMetric(label: "Added", value: summary.additions, color: .green)
      DiffMetric(label: "Removed", value: summary.deletions, color: .red)
      DiffMetric(label: "Hunks", value: summary.hunkCount, color: .blue)
      Spacer()
      if summary.isMetadataOnly {
        Label("Metadata-only change", systemImage: "info.circle")
          .foregroundStyle(.secondary)
      }
    }
    .font(.caption)
  }
}

private struct DiffMetric: View {
  var label: String
  var value: Int
  var color: Color

  var body: some View {
    HStack(spacing: 4) {
      Circle()
        .fill(color)
        .frame(width: 6, height: 6)
      Text(label)
      Text(value.formatted())
        .fontWeight(.semibold)
        .monospacedDigit()
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(.quaternary, in: Capsule())
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

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Image(systemName: result.isError ? "exclamationmark.triangle" : "checkmark.circle")
          .foregroundStyle(result.isError ? .orange : .green)
        Text(result.title)
          .font(.headline)
        Spacer()
      }
      Text(result.output)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .lineLimit(5)
        .textSelection(.enabled)
    }
    .padding(12)
    .background(.quaternary)
  }
}
