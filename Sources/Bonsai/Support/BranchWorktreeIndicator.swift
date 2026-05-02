import Foundation

struct BranchWorktreeIndicator: Equatable {
  enum Kind: Equatable {
    case current
    case linkedWorktree(name: String, path: String)
    case available
  }

  var kind: Kind

  init(
    branch: GitRef,
    worktrees: [GitWorktree],
    selectedRepositoryPath: String?
  ) {
    if branch.isHead {
      kind = .current
      return
    }

    if let worktree = worktrees.first(where: { worktree in
      worktree.branch == branch.name && worktree.path != selectedRepositoryPath
    }) {
      kind = .linkedWorktree(name: worktree.name, path: worktree.path)
      return
    }

    kind = .available
  }

  var systemImage: String {
    switch kind {
    case .current:
      return "checkmark.circle.fill"
    case .linkedWorktree:
      return "square.stack.3d.up.fill"
    case .available:
      return "circle"
    }
  }

  var helpText: String? {
    switch kind {
    case .current:
      return "Current branch"
    case let .linkedWorktree(name, path):
      return "Checked out in \(name)\n\(path)"
    case .available:
      return nil
    }
  }
}
