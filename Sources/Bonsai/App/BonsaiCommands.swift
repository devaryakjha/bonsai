import SwiftUI

struct BonsaiCommands: Commands {
  let store: RepositoryStore

  var body: some Commands {
    CommandMenu("Repository") {
      Button("Open Repository...") {
        store.presentOpenRepositoryPanel()
      }
      .keyboardShortcut("o", modifiers: [.command])

      Divider()

      Button("Fetch") {
        Task { await store.runRepositoryAction(.fetch) }
      }
      .keyboardShortcut("f", modifiers: [.command])
      .disabled(store.selectedRepository == nil)

      Button("Pull") {
        Task { await store.runRepositoryAction(.pull) }
      }
      .keyboardShortcut("u", modifiers: [.command, .shift])
      .disabled(store.selectedRepository == nil)

      Button("Push") {
        Task { await store.runRepositoryAction(.push) }
      }
      .keyboardShortcut("p", modifiers: [.command, .shift])
      .disabled(store.selectedRepository == nil)

      Divider()

      Button("Refresh") {
        Task { await store.refreshAll() }
      }
      .keyboardShortcut("r", modifiers: [.command])
      .disabled(store.selectedRepository == nil)
    }
  }
}
