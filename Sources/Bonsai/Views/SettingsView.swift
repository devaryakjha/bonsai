import SwiftUI

struct SettingsView: View {
  @AppStorage("bonsai.showToolbarLabels") private var showToolbarLabels = true
  @AppStorage("bonsai.autoRefresh") private var autoRefresh = true

  var body: some View {
    Form {
      Toggle("Show toolbar labels", isOn: $showToolbarLabels)
      Toggle("Refresh after Git operations", isOn: $autoRefresh)
    }
    .formStyle(.grouped)
    .padding()
    .frame(width: 420)
  }
}
