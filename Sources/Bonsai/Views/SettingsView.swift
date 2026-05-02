import SwiftUI

struct SettingsView: View {
  @AppStorage("bonsai.showToolbarLabels") private var showToolbarLabels = false
  @AppStorage("bonsai.autoRefresh") private var autoRefresh = true
  @AppStorage("bonsai.showCommitRowDetails") private var showCommitRowDetails = false
  @AppStorage("bonsai.diffAlgorithm") private var diffAlgorithm = DiffAlgorithm.histogram.rawValue
  @AppStorage("bonsai.diffWhitespaceMode") private var diffWhitespaceMode = DiffWhitespaceMode.show.rawValue
  @AppStorage("bonsai.diffDisplayMode") private var diffDisplayMode = DiffDisplayMode.unified.rawValue
  @AppStorage("bonsai.githubToken") private var githubToken = ""

  var body: some View {
    Form {
      Section("General") {
        Toggle("Show toolbar labels", isOn: $showToolbarLabels)
        Toggle("Show commit row details", isOn: $showCommitRowDetails)
        Toggle("Refresh after Git operations", isOn: $autoRefresh)
      }

      Section("Diff") {
        Picker("Diff algorithm", selection: $diffAlgorithm) {
          ForEach(DiffAlgorithm.allCases) { algorithm in
            Text(algorithm.title).tag(algorithm.rawValue)
          }
        }
        Picker("Whitespace", selection: $diffWhitespaceMode) {
          ForEach(DiffWhitespaceMode.allCases) { mode in
            Text(mode.title).tag(mode.rawValue)
          }
        }
        Picker("Diff view", selection: $diffDisplayMode) {
          ForEach(DiffDisplayMode.allCases) { mode in
            Text(mode.title).tag(mode.rawValue)
          }
        }
      }

      Section("Integrations") {
        SecureField("GitHub token", text: $githubToken)
      }
    }
    .formStyle(.grouped)
    .padding()
    .frame(width: 420)
  }
}
