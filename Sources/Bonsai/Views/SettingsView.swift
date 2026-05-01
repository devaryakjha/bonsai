import SwiftUI

struct SettingsView: View {
  @AppStorage("bonsai.showToolbarLabels") private var showToolbarLabels = true
  @AppStorage("bonsai.autoRefresh") private var autoRefresh = true
  @AppStorage("bonsai.diffAlgorithm") private var diffAlgorithm = DiffAlgorithm.histogram.rawValue

  var body: some View {
    Form {
      Toggle("Show toolbar labels", isOn: $showToolbarLabels)
      Toggle("Refresh after Git operations", isOn: $autoRefresh)
      Picker("Diff algorithm", selection: $diffAlgorithm) {
        ForEach(DiffAlgorithm.allCases) { algorithm in
          Text(algorithm.title).tag(algorithm.rawValue)
        }
      }
    }
    .formStyle(.grouped)
    .padding()
    .frame(width: 420)
  }
}
