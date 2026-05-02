import SwiftUI

struct DiffFindCommands: Commands {
  @FocusedBinding(\.diffFindVisible) private var isDiffFindVisible

  var body: some Commands {
    CommandGroup(after: .textEditing) {
      Button("Find in Diff") {
        isDiffFindVisible = true
      }
      .keyboardShortcut("f", modifiers: [.command])
      .disabled(isDiffFindVisible == nil)
    }
  }
}

private struct DiffFindVisibleKey: FocusedValueKey {
  typealias Value = Binding<Bool>
}

extension FocusedValues {
  var diffFindVisible: Binding<Bool>? {
    get { self[DiffFindVisibleKey.self] }
    set { self[DiffFindVisibleKey.self] = newValue }
  }
}
