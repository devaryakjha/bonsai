import SwiftUI

struct DiffFindCommands: Commands {
  @FocusedBinding(\.diffFindVisible) private var isDiffFindVisible
  @FocusedValue(\.diffFindNavigation) private var diffFindNavigation

  var body: some Commands {
    CommandGroup(after: .textEditing) {
      Button(DiffFindCommandCopy.findTitle) {
        isDiffFindVisible = true
      }
      .keyboardShortcut("f", modifiers: [.command])
      .disabled(isDiffFindVisible == nil)

      Button(DiffFindCommandCopy.findNextTitle) {
        diffFindNavigation?.navigate(.next)
      }
      .keyboardShortcut("g", modifiers: [.command])
      .disabled(diffFindNavigation?.canNavigate != true)

      Button(DiffFindCommandCopy.findPreviousTitle) {
        diffFindNavigation?.navigate(.previous)
      }
      .keyboardShortcut("g", modifiers: [.command, .shift])
      .disabled(diffFindNavigation?.canNavigate != true)
    }
  }
}

enum DiffFindCommandCopy {
  static let findTitle = "Find in Diff"
  static let findNextTitle = "Find Next in Diff"
  static let findPreviousTitle = "Find Previous in Diff"
  static let findShortcut = "Command-F"
  static let findNextShortcut = "Command-G"
  static let findPreviousShortcut = "Command-Shift-G"
}

struct DiffFindNavigationActions {
  var canNavigate: Bool
  var navigate: (DiffSearch.NavigationDirection) -> Void
}

private struct DiffFindVisibleKey: FocusedValueKey {
  typealias Value = Binding<Bool>
}

private struct DiffFindNavigationKey: FocusedValueKey {
  typealias Value = DiffFindNavigationActions
}

extension FocusedValues {
  var diffFindVisible: Binding<Bool>? {
    get { self[DiffFindVisibleKey.self] }
    set { self[DiffFindVisibleKey.self] = newValue }
  }

  var diffFindNavigation: DiffFindNavigationActions? {
    get { self[DiffFindNavigationKey.self] }
    set { self[DiffFindNavigationKey.self] = newValue }
  }
}
