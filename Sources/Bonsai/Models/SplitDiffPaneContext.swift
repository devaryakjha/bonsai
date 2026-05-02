struct SplitDiffPaneDescriptor: Hashable {
  var title: String
  var detail: String?
  var systemImage: String
}

struct SplitDiffPaneContext: Hashable {
  var old: SplitDiffPaneDescriptor
  var new: SplitDiffPaneDescriptor

  static let fallback = SplitDiffPaneContext(
    old: SplitDiffPaneDescriptor(title: "Before", detail: nil, systemImage: "minus.line.diagonal"),
    new: SplitDiffPaneDescriptor(title: "After", detail: nil, systemImage: "plus.line.diagonal")
  )

  static func workingTree(entry: GitStatusEntry) -> SplitDiffPaneContext {
    let oldTitle: String
    let oldDetail: String?
    let newTitle: String

    if entry.isStaged {
      oldTitle = "HEAD"
      oldDetail = entry.originalPath ?? entry.path
      newTitle = "Index"
    } else if entry.isUntracked {
      oldTitle = "No file"
      oldDetail = nil
      newTitle = "Working tree"
    } else {
      oldTitle = "HEAD"
      oldDetail = entry.originalPath ?? entry.path
      newTitle = "Working tree"
    }

    return SplitDiffPaneContext(
      old: SplitDiffPaneDescriptor(title: oldTitle, detail: oldDetail, systemImage: "minus.line.diagonal"),
      new: SplitDiffPaneDescriptor(title: newTitle, detail: entry.path, systemImage: "plus.line.diagonal")
    )
  }

  static func changedFile(_ file: GitChangedFile, oldTitle: String, newTitle: String) -> SplitDiffPaneContext {
    SplitDiffPaneContext(
      old: SplitDiffPaneDescriptor(
        title: oldTitle,
        detail: file.oldPath ?? file.path,
        systemImage: "minus.line.diagonal"
      ),
      new: SplitDiffPaneDescriptor(
        title: newTitle,
        detail: file.statusCode == "D" ? nil : file.path,
        systemImage: "plus.line.diagonal"
      )
    )
  }
}
