enum GitStatusRowPrimaryAction: Equatable {
  case stage
  case unstage
  case resolveConflict

  var title: String {
    switch self {
    case .stage:
      return "Stage"
    case .unstage:
      return "Unstage"
    case .resolveConflict:
      return "Resolve conflict"
    }
  }

  var systemImage: String {
    switch self {
    case .stage:
      return "plus.circle"
    case .unstage:
      return "minus.circle"
    case .resolveConflict:
      return "wrench.and.screwdriver"
    }
  }
}

extension GitStatusEntry {
  var primaryRowAction: GitStatusRowPrimaryAction {
    if isConflicted {
      return .resolveConflict
    }
    return isStaged ? .unstage : .stage
  }
}
