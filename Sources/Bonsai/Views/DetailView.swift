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
    VStack(alignment: .leading, spacing: 8) {
      if let commit = store.selectedCommit, store.mainMode == .history {
        Text(commit.subject)
          .font(.headline)
          .lineLimit(2)
        HStack {
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
        Text(entry.kind.rawValue)
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        Text("Diff")
          .font(.headline)
        Text("Select a commit file or working tree change")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

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
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
  }
}

private struct DiffView: View {
  let store: RepositoryStore

  var body: some View {
    VStack(spacing: 0) {
      if store.diffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Text("No diff selected")
          .foregroundStyle(.secondary)
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

        switch store.diffDisplayMode {
        case .unified:
          RichDiffTextView(text: store.diffText)
        case .split:
          SplitDiffTextView(splitDiff: store.splitDiff)
        }
      }
    }
  }

  private var shouldShowHunks: Bool {
    store.selectedStatusEntry != nil && !store.diffHunks.isEmpty
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
