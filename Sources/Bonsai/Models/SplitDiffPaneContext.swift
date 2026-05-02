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
    if entry.isConflicted {
      return conflictResolution(entry: entry, base: .base)
    }

    let oldHasFile = entry.kind != .added && !entry.isUntracked
    let newHasFile = entry.kind != .deleted

    if entry.isStaged {
      return SplitDiffPaneContext(
        old: SplitDiffPaneDescriptor(
          title: oldHasFile ? "HEAD" : "No file",
          detail: oldHasFile ? entry.originalPath ?? entry.path : nil,
          systemImage: "minus.line.diagonal"
        ),
        new: SplitDiffPaneDescriptor(
          title: newHasFile ? "Index" : "No file",
          detail: newHasFile ? entry.path : nil,
          systemImage: "plus.line.diagonal"
        )
      )
    }

    if entry.isUntracked {
      return SplitDiffPaneContext(
        old: SplitDiffPaneDescriptor(title: "No file", detail: nil, systemImage: "minus.line.diagonal"),
        new: SplitDiffPaneDescriptor(title: "Working tree", detail: entry.path, systemImage: "plus.line.diagonal")
      )
    }

    return SplitDiffPaneContext(
      old: SplitDiffPaneDescriptor(
        title: oldHasFile ? "HEAD" : "No file",
        detail: oldHasFile ? entry.originalPath ?? entry.path : nil,
        systemImage: "minus.line.diagonal"
      ),
      new: SplitDiffPaneDescriptor(
        title: newHasFile ? "Working tree" : "No file",
        detail: newHasFile ? entry.path : nil,
        systemImage: "plus.line.diagonal"
      )
    )
  }

  static func conflictResolution(entry: GitStatusEntry, base: ConflictDiffBase) -> SplitDiffPaneContext {
    SplitDiffPaneContext(
      old: SplitDiffPaneDescriptor(
        title: base.title,
        detail: entry.originalPath ?? entry.path,
        systemImage: "minus.line.diagonal"
      ),
      new: SplitDiffPaneDescriptor(
        title: "Working tree",
        detail: entry.path,
        systemImage: "plus.line.diagonal"
      )
    )
  }

  static func changedFile(_ file: GitChangedFile, oldTitle: String, newTitle: String) -> SplitDiffPaneContext {
    let oldHasFile = file.statusCode != "A"
    let newHasFile = file.statusCode != "D"

    return SplitDiffPaneContext(
      old: SplitDiffPaneDescriptor(
        title: oldHasFile ? oldTitle : "No file",
        detail: oldHasFile ? file.oldPath ?? file.path : nil,
        systemImage: "minus.line.diagonal"
      ),
      new: SplitDiffPaneDescriptor(
        title: newHasFile ? newTitle : "No file",
        detail: newHasFile ? file.path : nil,
        systemImage: "plus.line.diagonal"
      )
    )
  }
}
