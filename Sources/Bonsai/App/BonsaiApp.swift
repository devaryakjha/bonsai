import AppKit
import SwiftUI

@main
struct BonsaiApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @State private var repositoryStore = RepositoryStore()

  var body: some Scene {
    WindowGroup("Bonsai", id: "main") {
      ContentView(store: repositoryStore)
        .frame(minWidth: 1120, minHeight: 720)
    }
    .commands {
      BonsaiAppInfoCommands()
      BonsaiCommands(store: repositoryStore)
      DiffFindCommands()
    }

    Settings {
      SettingsView()
    }
  }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
    BonsaiAppBranding.installApplicationIcon()
    NSApp.activate(ignoringOtherApps: true)
  }
}
