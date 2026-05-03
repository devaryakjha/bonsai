import SwiftUI

struct SettingsView: View {
  @AppStorage("bonsai.showToolbarLabels") private var showToolbarLabels = false
  @AppStorage("bonsai.autoRefresh") private var autoRefresh = true
  @AppStorage("bonsai.showCommitRowDetails") private var showCommitRowDetails = false
  @AppStorage("bonsai.diffAlgorithm") private var diffAlgorithm = DiffAlgorithm.histogram.rawValue
  @AppStorage("bonsai.diffWhitespaceMode") private var diffWhitespaceMode = DiffWhitespaceMode.show.rawValue
  @AppStorage("bonsai.diffDisplayMode") private var diffDisplayMode = DiffDisplayMode.unified.rawValue
  @AppStorage("bonsai.githubToken") private var githubToken = ""
  @AppStorage(CodeAgentPromptPreferences.commitMessageRequestKey) private var commitMessageRequest = CodeAgentPromptPreferences.defaultCommitMessageRequest
  @AppStorage(CodeAgentPromptPreferences.branchReviewRequestKey) private var branchReviewRequest = CodeAgentPromptPreferences.defaultBranchReviewRequest
  @AppStorage(ProjectRepositoryScanner.sourceDirectoriesDefaultsKey) private var sourceDirectories = ProjectRepositoryScanner.defaultSourceDirectoryText

  var body: some View {
    VStack(alignment: .leading, spacing: 22) {
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
        SettingsRow("Source directories") {
          TextEditor(text: $sourceDirectories)
            .font(.body.monospaced())
            .frame(minHeight: 58, maxHeight: 74)
            .scrollContentBackground(.hidden)
            .help("One source directory per line")
            .accessibilityLabel("Source directories")
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
        SettingsRow("GitHub token") {
          SecureField("GitHub token", text: $githubToken)
            .textFieldStyle(.roundedBorder)
        }
        SettingsRow("Commit request") {
          PromptPreferenceEditor(
            text: $commitMessageRequest,
            resetHelp: "Reset commit request",
            onReset: {
              commitMessageRequest = CodeAgentPromptPreferences.defaultCommitMessageRequest
            }
          )
        }
        SettingsRow("Review request") {
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
    .padding(24)
    .frame(width: 560)
  }
}

private struct PromptPreferenceEditor: View {
  @Binding var text: String
  var resetHelp: String
  var onReset: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      TextEditor(text: $text)
        .font(.body.monospaced())
        .frame(minHeight: 66, maxHeight: 92)
        .scrollContentBackground(.hidden)
      Button(action: onReset) {
        Image(systemName: "arrow.counterclockwise")
      }
      .buttonStyle(.borderless)
      .help(resetHelp)
      .accessibilityLabel(resetHelp)
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
  }
}

private struct SettingsRow<Content: View>: View {
  var title: String
  var content: Content

  init(_ title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    HStack(alignment: .center, spacing: 16) {
      Text(title)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .frame(width: 132, alignment: .leading)
      content
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
