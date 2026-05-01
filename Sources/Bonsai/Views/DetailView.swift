import SwiftUI

struct DetailView: View {
  let store: RepositoryStore

  var body: some View {
    VStack(spacing: 0) {
      DetailHeaderView(store: store)
      Divider()
      DiffView(diffText: store.diffText)
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
  var diffText: String

  var body: some View {
    ScrollView([.vertical, .horizontal]) {
      LazyVStack(alignment: .leading, spacing: 0) {
        if diffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text("No diff selected")
            .foregroundStyle(.secondary)
            .padding()
        } else {
          ForEach(Array(diffText.split(separator: "\n", omittingEmptySubsequences: false).enumerated()), id: \.offset) { index, line in
            DiffLineView(number: index + 1, text: String(line))
          }
        }
      }
      .padding(.vertical, 8)
    }
    .font(.system(.caption, design: .monospaced))
    .textSelection(.enabled)
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
