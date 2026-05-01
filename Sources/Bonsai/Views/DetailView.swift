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
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
  }
}

private struct DiffView: View {
  let store: RepositoryStore

  var body: some View {
    ScrollView([.vertical, .horizontal]) {
      LazyVStack(alignment: .leading, spacing: 0) {
        if store.diffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text("No diff selected")
            .foregroundStyle(.secondary)
            .padding()
        } else if shouldShowHunks {
          ForEach(store.diffHunks) { hunk in
            DiffHunkView(
              hunk: hunk,
              isStaged: store.selectedStatusEntry?.isStaged == true,
              onStage: {
                Task {
                  if store.selectedStatusEntry?.isStaged == true {
                    await store.unstageHunk(hunk)
                  } else {
                    await store.stageHunk(hunk)
                  }
                }
              }
            )
          }
        } else {
          ForEach(Array(store.diffText.split(separator: "\n", omittingEmptySubsequences: false).enumerated()), id: \.offset) { index, line in
            DiffLineView(number: index + 1, text: String(line))
          }
        }
      }
      .padding(.vertical, 8)
    }
    .font(.system(.caption, design: .monospaced))
    .textSelection(.enabled)
  }

  private var shouldShowHunks: Bool {
    store.selectedStatusEntry != nil && !store.diffHunks.isEmpty
  }
}

private struct DiffHunkView: View {
  var hunk: DiffHunk
  var isStaged: Bool
  var onStage: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text(hunk.header)
          .foregroundStyle(.blue)
          .lineLimit(1)
        Spacer()
        Button {
          onStage()
        } label: {
          Label(isStaged ? "Unstage Hunk" : "Stage Hunk", systemImage: isStaged ? "minus.circle" : "plus.circle")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(.quaternary)

      ForEach(Array(hunk.lines.enumerated()), id: \.offset) { index, line in
        DiffLineView(number: index + 1, text: line)
      }
    }
    .padding(.bottom, 10)
  }
}

private struct DiffLineView: View {
  var number: Int
  var text: String

  var body: some View {
    HStack(spacing: 10) {
      Text(number.formatted())
        .foregroundStyle(.tertiary)
        .frame(width: 48, alignment: .trailing)
        .textSelection(.disabled)
      Text(text.isEmpty ? " " : text)
        .foregroundStyle(foregroundStyle)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 1)
    .background(backgroundStyle)
  }

  private var foregroundStyle: Color {
    if text.hasPrefix("+") && !text.hasPrefix("+++") {
      return .green
    }
    if text.hasPrefix("-") && !text.hasPrefix("---") {
      return .red
    }
    if text.hasPrefix("@@") {
      return .blue
    }
    return .primary
  }

  private var backgroundStyle: Color {
    if text.hasPrefix("+") && !text.hasPrefix("+++") {
      return Color.green.opacity(0.10)
    }
    if text.hasPrefix("-") && !text.hasPrefix("---") {
      return Color.red.opacity(0.10)
    }
    if text.hasPrefix("@@") {
      return Color.blue.opacity(0.08)
    }
    return Color.clear
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
