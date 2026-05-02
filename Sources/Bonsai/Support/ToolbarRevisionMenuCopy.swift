enum ToolbarRevisionMenuCopy {
  static let selectedCommitMenuTitle = "Selected Commit"
  static let currentOperationMenuTitle = "Current Operation"
  static let rebaseMenuTitle = "Rebase"
  static let bisectMenuTitle = "Bisect"

  static var groupTitles: [String] {
    [selectedCommitMenuTitle, currentOperationMenuTitle, rebaseMenuTitle, bisectMenuTitle]
  }
}
