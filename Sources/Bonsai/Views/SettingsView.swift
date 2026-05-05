import AppKit
import SwiftUI

struct SettingsView: View {
  @AppStorage("bonsai.showToolbarLabels") private var showToolbarLabels = false
  @AppStorage("bonsai.autoRefresh") private var autoRefresh = true
  @AppStorage(GitCommandOutputFormatter.verboseGitOutputKey) private var verboseGitOutput = false
  @AppStorage("bonsai.showCommitRowDetails") private var showCommitRowDetails = false
  @AppStorage("bonsai.diffAlgorithm") private var diffAlgorithm = DiffAlgorithm.histogram.rawValue
  @AppStorage("bonsai.diffWhitespaceMode") private var diffWhitespaceMode = DiffWhitespaceMode.show.rawValue
  @AppStorage("bonsai.diffDisplayMode") private var diffDisplayMode = DiffDisplayMode.unified.rawValue
  @AppStorage("bonsai.githubToken") private var githubToken = ""
  @AppStorage(CodeAgentPromptPreferences.commitMessageRequestKey) private var commitMessageRequest = CodeAgentPromptPreferences.defaultCommitMessageRequest
  @AppStorage(CodeAgentPromptPreferences.branchReviewRequestKey) private var branchReviewRequest = CodeAgentPromptPreferences.defaultBranchReviewRequest
  @AppStorage(ProjectRepositoryScanner.sourceDirectoriesDefaultsKey) private var sourceDirectories = ProjectRepositoryScanner.defaultSourceDirectoryText

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      SettingsSection("General") {
        SettingsRow("Toolbar labels") {
          Toggle("", isOn: $showToolbarLabels)
            .labelsHidden()
            .accessibilityLabel("Toolbar labels")
        }
        SettingsRow("Commit row details") {
          Toggle("", isOn: $showCommitRowDetails)
            .labelsHidden()
            .accessibilityLabel("Commit row details")
        }
        SettingsRow("Auto refresh") {
          Toggle("", isOn: $autoRefresh)
            .labelsHidden()
            .accessibilityLabel("Auto refresh")
        }
        SettingsRow("Verbose Git output") {
          Toggle("", isOn: $verboseGitOutput)
            .labelsHidden()
            .accessibilityLabel("Verbose Git output")
        }
        SettingsRow("Source directories", alignment: .top) {
          SourceDirectoryEditor(sourceDirectories: $sourceDirectories) {
            chooseSourceDirectory()
          }
        }
      }

      SettingsSection("Diff") {
        SettingsRow("Algorithm") {
          Picker("Algorithm", selection: $diffAlgorithm) {
            ForEach(DiffAlgorithm.allCases) { algorithm in
              Text(algorithm.title).tag(algorithm.rawValue)
            }
          }
          .pickerStyle(.segmented)
          .labelsHidden()
          .accessibilityLabel("Algorithm")
        }
        SettingsRow("Whitespace") {
          Picker("Whitespace", selection: $diffWhitespaceMode) {
            ForEach(DiffWhitespaceMode.allCases) { mode in
              Text(mode.title).tag(mode.rawValue)
            }
          }
          .labelsHidden()
          .accessibilityLabel("Whitespace")
        }
        SettingsRow("View") {
          Picker("View", selection: $diffDisplayMode) {
            ForEach(DiffDisplayMode.allCases) { mode in
              Text(mode.title).tag(mode.rawValue)
            }
          }
          .pickerStyle(.segmented)
          .labelsHidden()
          .accessibilityLabel("Diff view")
        }
      }

      SettingsSection("Integrations") {
        SettingsRow("GitHub token", alignment: .top) {
          VStack(alignment: .leading, spacing: 5) {
            SecureField("GitHub token", text: $githubToken)
              .textFieldStyle(.roundedBorder)
            Text(gitHubTokenStatus)
              .font(.caption)
              .foregroundStyle(gitHubTokenStatusColor)
          }
        }
        SettingsRow("Commit request", alignment: .top) {
          PromptPreferenceEditor(
            text: $commitMessageRequest,
            resetHelp: "Reset commit request",
            onReset: {
              commitMessageRequest = CodeAgentPromptPreferences.defaultCommitMessageRequest
            }
          )
        }
        SettingsRow("Review request", alignment: .top) {
          PromptPreferenceEditor(
            text: $branchReviewRequest,
            resetHelp: "Reset review request",
            onReset: {
              branchReviewRequest = CodeAgentPromptPreferences.defaultBranchReviewRequest
            }
          )
        }
      }
    }
    .padding(.horizontal, 28)
    .padding(.vertical, 26)
    .frame(width: 680)
  }

  private var gitHubTokenStatus: String {
    githubToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ? "Used for GitHub notifications and repository actions. Saved automatically."
      : "Token saved automatically."
  }

  private var gitHubTokenStatusColor: Color {
    githubToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .green
  }

  private func chooseSourceDirectory() {
    let panel = NSOpenPanel()
    panel.title = "Add Source Directory"
    panel.prompt = "Add"
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    guard panel.runModal() == .OK, let url = panel.url else { return }

    let path = url.path(percentEncoded: false)
    var lines = sourceDirectories
      .split(separator: "\n", omittingEmptySubsequences: false)
      .map(String.init)
    guard !lines.contains(path) else { return }
    if lines == [""] {
      lines = [path]
    } else {
      lines.append(path)
    }
    sourceDirectories = lines.joined(separator: "\n")
  }
}

private struct SourceDirectoryEditor: View {
  @Binding var sourceDirectories: String
  var onAddFolder: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(spacing: 0) {
        if sourceDirectoryLines.isEmpty {
          Text("No source directories")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        } else {
          ForEach(Array(sourceDirectoryLines.enumerated()), id: \.offset) { index, path in
            HStack(spacing: 8) {
              Image(systemName: "folder")
                .foregroundStyle(.secondary)
              Text(path)
                .font(.body.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
                .help(path)
              Spacer(minLength: 8)
              Button {
                removeSourceDirectory(at: index)
              } label: {
                Image(systemName: "minus.circle")
              }
              .buttonStyle(.borderless)
              .help("Remove source directory")
              .accessibilityLabel("Remove source directory")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)

            if index < sourceDirectoryLines.count - 1 {
              Divider()
            }
          }
        }
      }
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 7))
      .overlay {
        RoundedRectangle(cornerRadius: 7)
          .stroke(Color(nsColor: .separatorColor).opacity(0.8))
      }

      HStack(spacing: 8) {
        Button {
          onAddFolder()
        } label: {
          Label("Add folder", systemImage: "folder.badge.plus")
        }
        .controlSize(.small)
        Text("Saved automatically.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var sourceDirectoryLines: [String] {
    sourceDirectories
      .split(separator: "\n")
      .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  private func removeSourceDirectory(at index: Int) {
    var lines = sourceDirectoryLines
    guard lines.indices.contains(index) else { return }
    lines.remove(at: index)
    sourceDirectories = lines.joined(separator: "\n")
  }
}

private struct PromptPreferenceEditor: View {
  @Binding var text: String
  var resetHelp: String
  var onReset: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ZStack(alignment: .topTrailing) {
        FramedTextEditor(text: $text, minHeight: 76, maxHeight: 104)
          .padding(.trailing, 32)
        Button(action: onReset) {
          Image(systemName: "arrow.counterclockwise")
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .padding(.top, 8)
        .padding(.trailing, 8)
        .help(resetHelp)
        .accessibilityLabel(resetHelp)
      }
      Text("Saved automatically.")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

private struct FramedTextEditor: View {
  @Binding var text: String
  var minHeight: CGFloat
  var maxHeight: CGFloat

  var body: some View {
    TextEditor(text: $text)
      .font(.body.monospaced())
      .frame(minHeight: minHeight, maxHeight: maxHeight)
      .scrollContentBackground(.hidden)
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(Color(nsColor: .textBackgroundColor).opacity(0.72), in: RoundedRectangle(cornerRadius: 7))
      .overlay {
        RoundedRectangle(cornerRadius: 7)
          .stroke(Color(nsColor: .separatorColor).opacity(0.9))
      }
  }
}

private struct SettingsSection<Content: View>: View {
  var title: String
  var content: Content

  init(_ title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.headline)
        .lineLimit(1)
      VStack(alignment: .leading, spacing: 8) {
        content
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct SettingsRow<Content: View>: View {
  var title: String
  var alignment: VerticalAlignment
  var content: Content

  init(_ title: String, alignment: VerticalAlignment = .center, @ViewBuilder content: () -> Content) {
    self.title = title
    self.alignment = alignment
    self.content = content()
  }

  var body: some View {
    HStack(alignment: alignment, spacing: 18) {
      Text(title)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .frame(width: 156, alignment: .leading)
        .padding(.top, alignment == .top ? 7 : 0)
      content
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
