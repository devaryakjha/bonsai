import SwiftUI

struct BonsaiAppInfoCommands: Commands {
  var body: some Commands {
    CommandGroup(replacing: .appInfo) {
      Button("About Bonsai") {
        BonsaiAppBranding.showAboutPanel()
      }
    }
  }
}
