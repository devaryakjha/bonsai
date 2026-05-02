import AppKit

enum NavigationFocusTarget: Hashable {
  case sidebar
  case history

  static func tabDestination(from current: NavigationFocusTarget?) -> NavigationFocusTarget {
    current == .sidebar ? .history : .sidebar
  }

  static var canHandleTabShortcut: Bool {
    guard let firstResponder = NSApp.keyWindow?.firstResponder else {
      return true
    }
    return !(firstResponder is NSTextView) && !(firstResponder is NSTextField)
  }
}
