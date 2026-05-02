import SwiftUI

struct StashCopyMenu: View {
  var stash: GitStash

  var body: some View {
    Button("Copy Stash Reference") {
      PasteboardWriter.copy(stash.index)
    }
    Button("Copy Message") {
      PasteboardWriter.copy(stash.message)
    }
    if let branch = stash.branch, !branch.isEmpty {
      Button("Copy Branch") {
        PasteboardWriter.copy(branch)
      }
    }
  }
}
